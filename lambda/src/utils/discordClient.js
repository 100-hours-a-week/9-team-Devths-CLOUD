const https = require('https');

/**
 * Discord Webhook을 통해 메시지를 전송합니다
 * @param {Object} message - Discord 메시지 객체 (embeds, content 등)
 * @returns {Promise<string>} - 전송 결과
 */
function sendToDiscord(message) {
    return new Promise((resolve, reject) => {
        const webhookUrl = process.env.DISCORD_WEBHOOK;

        if (!webhookUrl) {
            reject(new Error('DISCORD_WEBHOOK environment variable not set'));
            return;
        }

        const url = new URL(webhookUrl);
        const payload = JSON.stringify(message);

        const options = {
            hostname: url.hostname,
            path: url.pathname + url.search,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';

            res.on('data', (chunk) => {
                data += chunk;
            });

            res.on('end', () => {
                if (res.statusCode >= 200 && res.statusCode < 300) {
                    console.log('Message sent to Discord successfully');
                    resolve(data);
                } else {
                    reject(new Error(`Discord API error: ${res.statusCode} - ${data}`));
                }
            });
        });

        req.on('error', (error) => {
            reject(error);
        });

        req.write(payload);
        req.end();
    });
}

module.exports = { sendToDiscord };
