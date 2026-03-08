const { getAlarmColor, getAlarmEmoji } = require('../utils/formatting');
const { handleSecurityAlarm } = require('./securityHandler');

/**
 * CloudWatch Alarm 이벤트를 처리합니다
 * @param {Object} snsMessage - SNS 메시지 객체
 * @returns {Promise<Object>} - Discord 메시지 객체
 */
async function handleCloudWatchAlarm(snsMessage) {
    const message = JSON.parse(snsMessage.Message);

    // Security/Logs 네임스페이스나 Dangerous 키워드 알람인 경우 특별 처리
    const isSecurity = message.Trigger?.Namespace?.includes('Security') ||
                       message.AlarmName?.toLowerCase().includes('dangerous') ||
                       message.AlarmName?.toLowerCase().includes('security');

    if (isSecurity && message.NewStateValue === 'ALARM') {
        return handleSecurityAlarm(message);
    }

    const color = getAlarmColor(message.NewStateValue);
    const emoji = getAlarmEmoji(message.NewStateValue);

    return {
        embeds: [{
            title: `${emoji} CloudWatch Alarm: ${message.AlarmName}`,
            description: message.AlarmDescription || 'No description provided',
            color: color,
            fields: [
                {
                    name: 'State Change',
                    value: `${message.OldStateValue} → **${message.NewStateValue}**`,
                    inline: true
                },
                {
                    name: 'Metric',
                    value: message.Trigger?.MetricName || 'N/A',
                    inline: true
                },
                {
                    name: 'Namespace',
                    value: message.Trigger?.Namespace || 'N/A',
                    inline: true
                },
                {
                    name: 'Reason',
                    value: message.NewStateReason || 'No reason provided',
                    inline: false
                },
                {
                    name: 'Region',
                    value: message.Region || 'N/A',
                    inline: true
                },
                {
                    name: 'Account',
                    value: message.AWSAccountId || 'N/A',
                    inline: true
                }
            ],
            timestamp: new Date(message.StateChangeTime).toISOString(),
            footer: {
                text: 'CloudWatch Alarm'
            }
        }]
    };
}

module.exports = { handleCloudWatchAlarm };
