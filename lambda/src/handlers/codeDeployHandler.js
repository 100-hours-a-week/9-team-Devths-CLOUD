/**
 * CodeDeploy SNS 알림을 Discord 메시지로 변환합니다
 * @param {Object} message - SNS 메시지(JSON 파싱된 CodeDeploy 이벤트)
 * @returns {Promise<Object>} - Discord 메시지 객체
 */
async function handleCodeDeployEvent(message) {
    const state = (message.status || message.state || 'UNKNOWN').toUpperCase();
    const meta = STATE_META[state] || DEFAULT_STATE_META(state);
    const region = message.region || process.env.AWS_REGION || 'ap-northeast-2';
    const deploymentId = message.deploymentId || 'N/A';
    const deploymentLink = deploymentId !== 'N/A'
        ? `[${deploymentId}](https://console.aws.amazon.com/codesuite/codedeploy/deployments/${deploymentId}?region=${region})`
        : 'N/A';

    const mention = FAILURE_STATES.has(state)
        ? (process.env.DISCORD_ROLE_ID ? `<@&${process.env.DISCORD_ROLE_ID}>` : '@here')
        : '';

    const fields = [
        {
            name: '상태',
            value: `**${meta.label}**`,
            inline: true
        },
        {
            name: '배포 대상',
            value: `앱: **${message.applicationName || 'N/A'}**\n그룹: **${message.deploymentGroupName || 'N/A'}**`,
            inline: true
        },
        {
            name: '배포 ID',
            value: deploymentLink,
            inline: true
        },
        {
            name: '시간',
            value: `시작: ${formatTime(message.createTime)}\n완료: ${formatTime(message.completeTime)}`,
            inline: true
        },
        {
            name: '리전/계정',
            value: `Region: ${region}\nAccount: ${message.accountId || 'N/A'}`,
            inline: true
        },
        {
            name: '트리거',
            value: message.eventTriggerName || 'N/A',
            inline: true
        }
    ];

    if (message.instanceId) {
        fields.push({
            name: '인스턴스',
            value: message.instanceId,
            inline: true
        });
    }

    if (message.instanceGroupName || message.instanceGroupId) {
        fields.push({
            name: '인스턴스 그룹',
            value: message.instanceGroupName || message.instanceGroupId,
            inline: true
        });
    }

    if (message.rollbackInfo?.rollbackDeploymentId) {
        fields.push({
            name: '롤백',
            value: `Rollback ID: ${message.rollbackInfo.rollbackDeploymentId}`,
            inline: false
        });
    }

    return {
        content: mention ? `${mention} CodeDeploy 배포 알림` : undefined,
        embeds: [{
            title: `${meta.emoji} CodeDeploy: ${meta.label}`,
            description: message.statusMessage || 'CodeDeploy 상태 변경 알림입니다.',
            color: meta.color,
            fields: fields,
            timestamp: formatTime(message.completeTime) !== 'N/A'
                ? formatTime(message.completeTime)
                : new Date().toISOString(),
            footer: {
                text: 'AWS CodeDeploy'
            }
        }]
    };
}

function formatTime(value) {
    if (!value) return 'N/A';

    const numeric = Number(value);
    if (!Number.isNaN(numeric)) {
        return new Date(numeric * 1000).toISOString();
    }

    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? 'N/A' : date.toISOString();
}

function DEFAULT_STATE_META(state) {
    return {
        label: state,
        color: 9807270, // Gray
        emoji: '📦'
    };
}

const STATE_META = {
    SUCCEEDED: { label: '배포 성공', color: 3066993, emoji: '✅' },
    SUCCESS: { label: '배포 성공', color: 3066993, emoji: '✅' },
    FAILED: { label: '배포 실패', color: 15158332, emoji: '🚨' },
    FAILURE: { label: '배포 실패', color: 15158332, emoji: '🚨' },
    STOPPED: { label: '배포 중지', color: 15105570, emoji: '⏹️' },
    STOPPING: { label: '배포 중지', color: 15105570, emoji: '⏹️' },
    IN_PROGRESS: { label: '배포 진행 중', color: 3447003, emoji: '🚧' },
    CREATED: { label: '배포 생성', color: 9807270, emoji: '🕒' },
    QUEUED: { label: '대기 중', color: 9807270, emoji: '⏳' },
    READY_FOR_TRAFFIC: { label: '트래픽 전환 완료', color: 3066993, emoji: '🌐' }
};

const FAILURE_STATES = new Set(['FAILED', 'FAILURE', 'STOPPED', 'STOPPING']);

module.exports = { handleCodeDeployEvent };
