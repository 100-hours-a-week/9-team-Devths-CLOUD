/**
 * CloudWatch Logs에서 최근 위험한 명령어 로그를 조회합니다
 */

// AWS SDK v3 사용 (Lambda 런타임에 기본 포함)
const { CloudWatchLogsClient, FilterLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');

/**
 * 위험한 명령어 패턴
 */
const DANGEROUS_PATTERNS = [
    'rm -rf',
    'rm -fr',
    'chmod 777',
    'chmod 666',
    'mkfs',
    'iptables -F',
    'ufw disable',
    'setenforce 0',
    'wget http',
    'curl http',
    'bash -i',
    'nc -e',
    'dd if=',
    '/dev/tcp/',
    'base64 -d',
    'eval $(',
    'systemctl stop',
    'kill -9',
    'userdel',
    'sudo su'
];

/**
 * ANSI 이스케이프 시퀀스 및 특수 문자 제거
 * @param {string} text - 원본 텍스트
 * @returns {string} - 정리된 텍스트
 */
function cleanSessionData(text) {
    if (!text) return '';

    return text
        // ANSI 이스케이프 시퀀스 제거
        .replace(/\x1b\[[0-9;]*[a-zA-Z]/g, '')
        .replace(/\x1b\][0-9];[^\x07]*\x07/g, '')
        // 제어 문자 제거
        .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
        // 연속된 공백 정리
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * SSM Session Manager 로그 파싱
 * @param {string} messageStr - @message 필드 (JSON 문자열)
 * @returns {Object|null} - 파싱된 로그 정보
 */
function parseSSMLog(messageStr) {
    try {
        const log = JSON.parse(messageStr);

        // userIdentity에서 사용자 정보 추출
        const userArn = log.userIdentity?.arn || 'Unknown';
        const userName = userArn.split('/').pop() || userArn.split(':').pop();

        // sessionData에서 실제 명령어 추출
        const sessionData = log.sessionData || [];
        const commands = sessionData
            .map(data => cleanSessionData(data))
            .filter(cmd => cmd && cmd.length > 0)
            .join(' ');

        return {
            user: userName,
            userArn: userArn,
            runAsUser: log.runAsUser || 'Unknown',
            instanceId: log.target?.id || 'Unknown',
            sessionId: log.sessionId || 'Unknown',
            command: commands,
            region: log.awsRegion || 'Unknown',
            eventTime: log.eventTime || new Date().toISOString()
        };
    } catch (error) {
        console.error('Failed to parse SSM log:', error);
        return null;
    }
}

/**
 * CloudWatch Logs에서 최근 위험한 명령어를 조회합니다
 * @param {string} logGroupName - 로그 그룹 이름
 * @param {number} minutes - 조회할 시간 범위 (분)
 * @returns {Promise<Array>} - 위험한 명령어 로그 배열
 */
async function queryDangerousCommands(logGroupName, minutes = 5) {
    const client = new CloudWatchLogsClient({
        region: process.env.AWS_REGION || 'ap-northeast-2'
    });

    const endTime = Date.now();
    const startTime = endTime - (minutes * 60 * 1000);

    try {
        const command = new FilterLogEventsCommand({
            logGroupName: logGroupName,
            startTime: startTime,
            endTime: endTime,
            limit: 100 // 최대 100개 로그만 조회
        });

        const response = await client.send(command);

        if (!response.events || response.events.length === 0) {
            return [];
        }

        // 로그 파싱 및 위험한 패턴 필터링
        const dangerousLogs = response.events
            .map(event => {
                const message = event.message || '';

                // SSM 로그 형식인 경우 파싱
                let parsedLog = null;
                if (message.includes('userIdentity') && message.includes('sessionData')) {
                    parsedLog = parseSSMLog(message);
                }

                // 위험한 패턴 확인
                const isDangerous = DANGEROUS_PATTERNS.some(pattern =>
                    message.toLowerCase().includes(pattern.toLowerCase())
                );

                if (!isDangerous) {
                    return null;
                }

                // SSM 로그인 경우 구조화된 정보 반환
                if (parsedLog) {
                    return {
                        timestamp: new Date(event.timestamp).toISOString(),
                        user: parsedLog.user,
                        userArn: parsedLog.userArn,
                        runAsUser: parsedLog.runAsUser,
                        instanceId: parsedLog.instanceId,
                        command: parsedLog.command,
                        region: parsedLog.region,
                        logStream: event.logStreamName,
                        type: 'ssm'
                    };
                }

                // 일반 로그인 경우
                return {
                    timestamp: new Date(event.timestamp).toISOString(),
                    message: message.substring(0, 500),
                    logStream: event.logStreamName,
                    type: 'generic'
                };
            })
            .filter(log => log !== null)
            .slice(0, 10); // 최대 10개만 반환

        return dangerousLogs;
    } catch (error) {
        console.error('Error querying CloudWatch Logs:', error);
        // 에러가 발생해도 알림은 계속 보내도록 빈 배열 반환
        return [];
    }
}

/**
 * 환경 변수에서 로그 그룹 이름을 가져오거나 메시지에서 추출합니다
 * @param {Object} message - CloudWatch Alarm 메시지
 * @returns {string|null} - 로그 그룹 이름 또는 null
 */
function getLogGroupName(message) {
    // 1. 환경 변수에서 확인
    if (process.env.LOG_GROUP_NAME) {
        return process.env.LOG_GROUP_NAME;
    }

    // 2. 알람 이름이나 설명에서 추출 시도
    const alarmName = message.AlarmName || '';
    const description = message.AlarmDescription || '';

    // 일반적인 로그 그룹 패턴 추출
    const patterns = [
        /log[- ]?group[:\s]+([\/\w\-]+)/i,
        /\/aws\/[\w\/\-]+/g
    ];

    for (const pattern of patterns) {
        const match = (alarmName + ' ' + description).match(pattern);
        if (match) {
            return match[1] || match[0];
        }
    }

    // 3. 기본값 반환 (환경 변수로 설정 필요)
    return null;
}

module.exports = {
    queryDangerousCommands,
    getLogGroupName,
    DANGEROUS_PATTERNS
};
