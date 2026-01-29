/**
 * Alarm 상태에 따른 Discord Embed 색상을 반환합니다
 * @param {string} state - Alarm 상태 (ALARM, OK, INSUFFICIENT_DATA)
 * @returns {number} - Discord Embed 색상 코드
 */
function getAlarmColor(state) {
    switch (state) {
        case 'ALARM':
            return 15158332; // Red
        case 'OK':
            return 3066993; // Green
        case 'INSUFFICIENT_DATA':
            return 16776960; // Yellow
        default:
            return 9807270; // Gray
    }
}

/**
 * Alarm 상태에 따른 이모지를 반환합니다
 * @param {string} state - Alarm 상태 (ALARM, OK, INSUFFICIENT_DATA)
 * @returns {string} - 이모지
 */
function getAlarmEmoji(state) {
    switch (state) {
        case 'ALARM':
            return '🚨';
        case 'OK':
            return '✅';
        case 'INSUFFICIENT_DATA':
            return '⚠️';
        default:
            return '📊';
    }
}

module.exports = {
    getAlarmColor,
    getAlarmEmoji
};
