const { queryDangerousCommands, getLogGroupName } = require('../utils/logsQuery');

/**
 * 보안 알람 특화 처리 (위험한 명령어 등)
 * @param {Object} message - CloudWatch Alarm 메시지
 * @returns {Promise<Object>} - Discord 메시지 객체 (강조된 보안 알림)
 */
async function handleSecurityAlarm(message) {
    // CloudWatch Logs에서 실제 위험한 명령어 조회
    const logGroupName = getLogGroupName(message);
    let dangerousLogs = [];

    if (logGroupName) {
        console.log(`Querying logs from: ${logGroupName}`);
        dangerousLogs = await queryDangerousCommands(logGroupName, 5);
    } else {
        console.warn('Log group name not found. Set LOG_GROUP_NAME environment variable.');
    }

    // 실제 명령어 내용 포맷팅
    let actualCommandsField;
    if (dangerousLogs.length > 0) {
        const commandsList = dangerousLogs
            .map((log, index) => {
                // SSM 로그인 경우
                if (log.type === 'ssm') {
                    return `**${index + 1}. [${log.timestamp}]**\n` +
                           `👤 **IAM 사용자**: ${log.user}\n` +
                           `   └ ARN: \`${log.userArn}\`\n` +
                           `🖥️  **EC2 인스턴스**: \`${log.instanceId}\`\n` +
                           `💻 **실행 계정**: \`${log.runAsUser}\`\n` +
                           `📝 **입력 명령어**: \`\`\`${log.command || '(명령어 감지 안됨)'}\`\`\``;
                }
                // 일반 로그인 경우
                return `${index + 1}. [${log.timestamp}]\n\`\`\`\n${log.message ? log.message.substring(0, 200) : '로그 없음'}\n\`\`\``;
            })
            .join('\n\n');

        actualCommandsField = {
            name: '🔴 실제 감지된 활동',
            value: commandsList.substring(0, 1000),
            inline: false
        };
    } else {
        actualCommandsField = {
            name: '🔴 실제 감지된 활동',
            value: '```\n로그 조회 실패 또는 로그 그룹 미설정\n환경 변수 LOG_GROUP_NAME 설정 필요\n```',
            inline: false
        };
    }

    // Discord 멘션 (환경 변수로 역할 ID 지정 가능)
    const mention = process.env.DISCORD_ROLE_ID
        ? `<@&${process.env.DISCORD_ROLE_ID}>`
        : '@everyone';

    return {
        content: `${mention} **⚠️ 보안 알림 발생!**`,
        embeds: [{
            title: '🚨 보안 위협 감지: 위험한 명령어 실행됨',
            description: '**긴급 조치가 필요합니다!**\n\nCloudWatch Logs에서 위험한 명령어 패턴이 감지되었습니다.',
            color: 16711680, // 진한 빨강
            fields: [
                {
                    name: '⚡ 알람명',
                    value: `**${message.AlarmName}**`,
                    inline: false
                },
                {
                    name: '📊 감지된 지표',
                    value: message.Trigger?.MetricName || 'DangerousCommandCount',
                    inline: true
                },
                {
                    name: '🔢 감지 횟수',
                    value: '1회 이상',
                    inline: true
                },
                {
                    name: '📍 위치',
                    value: `Region: ${message.Region || 'N/A'}\nAccount: ${message.AWSAccountId || 'N/A'}`,
                    inline: false
                },
                actualCommandsField,
                {
                    name: '📝 상세 원인',
                    value: message.NewStateReason || 'Threshold exceeded',
                    inline: false
                },
                {
                    name: '🔍 조치사항',
                    value: '1. CloudWatch Logs에서 정확한 명령어 확인\n' +
                           '2. 해당 사용자/프로세스 식별\n' +
                           '3. 인스턴스 격리 또는 접근 차단 고려\n' +
                           '4. 보안 팀에 에스컬레이션',
                    inline: false
                },
                {
                    name: '🔗 CloudWatch 바로가기',
                    value: `[CloudWatch Logs 확인](https://console.aws.amazon.com/cloudwatch/home?region=${message.Region}#logsV2:log-groups)\n` +
                           `[알람 상세정보](https://console.aws.amazon.com/cloudwatch/home?region=${message.Region}#alarmsV2:alarm/${encodeURIComponent(message.AlarmName)})`,
                    inline: false
                }
            ],
            timestamp: new Date(message.StateChangeTime).toISOString(),
            footer: {
                text: '🔒 Security Alert | CloudWatch'
            }
        }]
    };
}

module.exports = { handleSecurityAlarm };
