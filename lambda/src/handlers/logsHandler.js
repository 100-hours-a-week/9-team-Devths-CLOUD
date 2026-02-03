const zlib = require('zlib');

/**
 * CloudWatch Logs 이벤트를 처리합니다 (옵션)
 * @param {Object} event - CloudWatch Logs 이벤트
 * @returns {Promise<Object>} - Discord 메시지 객체
 */
async function handleCloudWatchLogs(event) {
    // Base64로 압축된 로그 데이터 디코딩
    const payload = Buffer.from(event.awslogs.data, 'base64');
    const parsed = JSON.parse(zlib.gunzipSync(payload).toString());

    return {
        embeds: [{
            title: '📋 CloudWatch Logs Alert',
            description: `Log Group: ${parsed.logGroup}`,
            color: 3447003, // Blue
            fields: [
                {
                    name: 'Log Stream',
                    value: parsed.logStream || 'N/A',
                    inline: false
                },
                {
                    name: 'Log Events',
                    value: parsed.logEvents.map(e =>
                        `\`${new Date(e.timestamp).toISOString()}\`: ${e.message.substring(0, 100)}`
                    ).join('\n').substring(0, 1000),
                    inline: false
                }
            ],
            timestamp: new Date().toISOString(),
            footer: {
                text: 'CloudWatch Logs'
            }
        }]
    };
}

/**
 * 직접 이벤트 처리 (테스트용)
 * @param {Object} event - 테스트 이벤트
 * @returns {Promise<Object>} - Discord 메시지 객체
 */
async function handleDirectEvent(event) {
    return {
        embeds: [{
            title: '⚠️ Custom CloudWatch Alert',
            description: 'Custom monitoring event detected',
            color: 16776960, // Yellow
            fields: [
                {
                    name: 'Event Data',
                    value: '```json\n' + JSON.stringify(event, null, 2).substring(0, 900) + '\n```',
                    inline: false
                }
            ],
            timestamp: new Date().toISOString(),
            footer: {
                text: 'Custom Event'
            }
        }]
    };
}

module.exports = {
    handleCloudWatchLogs,
    handleDirectEvent
};
