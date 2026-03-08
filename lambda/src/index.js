/**
 * CloudWatch 알림을 Discord로 전송하는 Lambda 함수
 * CloudWatch Alarm (SNS 트리거) 및 Logs 지원
 */

const { handleCloudWatchAlarm } = require('./src/handlers/alarmHandler');
const { handleCloudWatchLogs, handleDirectEvent } = require('./src/handlers/logsHandler');
const { handleCodeDeployEvent } = require('./src/handlers/codeDeployHandler');
const { sendToDiscord } = require('./src/utils/discordClient');

/**
 * Lambda 핸들러 함수
 * @param {Object} event - Lambda 이벤트 객체
 * @returns {Promise<Object>} - 응답 객체
 */
exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    try {
        let message;

        // SNS를 통한 CloudWatch Alarm 이벤트 처리
        if (event.Records && event.Records[0].Sns) {
            const snsRecord = event.Records[0].Sns;
            const parsedMessage = parseJsonSafe(snsRecord.Message);

            if (isCodeDeployMessage(parsedMessage)) {
                message = await handleCodeDeployEvent(parsedMessage);
            } else {
                message = await handleCloudWatchAlarm(snsRecord);
            }
        }
        // CloudWatch Logs 이벤트 처리 (옵션)
        else if (event.awslogs && event.awslogs.data) {
            message = await handleCloudWatchLogs(event);
        }
        // 테스트 또는 직접 이벤트 처리
        else {
            message = await handleDirectEvent(event);
        }

        // Discord로 메시지 전송
        await sendToDiscord(message);

        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Notification sent successfully' })
        };
    } catch (error) {
        console.error('Error processing event:', error);
        throw error;
    }
};

/**
 * SNS 메시지를 안전하게 파싱합니다
 * @param {string} message
 * @returns {Object|null}
 */
function parseJsonSafe(message) {
    try {
        return JSON.parse(message);
    } catch (error) {
        console.warn('Failed to parse SNS message as JSON:', error);
        return null;
    }
}

/**
 * CodeDeploy 알림인지 확인합니다
 * @param {Object|null} message
 * @returns {boolean}
 */
function isCodeDeployMessage(message) {
    if (!message) return false;

    // CodeDeploy SNS 메시지는 deploymentId 필드를 포함하고, applicationName 또는 deploymentGroupName을 가집니다
    return Boolean(
        message.deploymentId &&
        (message.applicationName || message.deploymentGroupName || message.status)
    );
}
