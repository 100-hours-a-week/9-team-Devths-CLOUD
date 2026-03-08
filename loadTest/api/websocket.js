/**
 * WebSocket 채팅 API
 *
 * K6 WebSocket 모듈 + STOMP 프레임을 사용한 실시간 채팅 부하 테스트
 */

import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { BASE_URL } from '../lib/config.js';

// WebSocket 전용 커스텀 메트릭
export const wsMetrics = {
  connectionTime: new Trend('ws_connection_time', true),
  messageSendTime: new Trend('ws_message_send_time', true),
  messageReceiveTime: new Trend('ws_message_receive_time', true),
  errorRate: new Rate('ws_error_rate'),
  activeConnections: new Counter('ws_active_connections'),
  messagesReceived: new Counter('ws_messages_received'),
  messagesSent: new Counter('ws_messages_sent'),
};

const STOMP_ENDPOINT_PREFIX = '/ws/chat';
const STOMP_APP_DESTINATION = '/app/chat/message';
const STOMP_TOPIC_PREFIX = '/topic/chatroom/';
const STOMP_CONNECT_TIMEOUT_MS = parseInt(__ENV.K6_WS_CONNECT_TIMEOUT_MS || '10000', 10);
const WS_USE_SOCKJS = (__ENV.K6_WS_USE_SOCKJS || 'true').toLowerCase() === 'true';

/**
 * WebSocket URL 생성
 * HTTP/HTTPS를 WS/WSS로 변환
 */
function getWebSocketUrl(path) {
  const wsUrl = BASE_URL.replace('https://', 'wss://').replace('http://', 'ws://');
  return `${wsUrl}${path}`;
}

function buildSockJsWebSocketPath() {
  // SockJS websocket transport: /{endpoint}/{server-id}/{session-id}/websocket
  const serverId = `${Math.floor(Math.random() * 1000)}`.padStart(3, '0');
  const sessionId = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 10)}`;
  return `${STOMP_ENDPOINT_PREFIX}/${serverId}/${sessionId}/websocket`;
}

function encodeSockJsPayload(payload) {
  return JSON.stringify([payload]);
}

function decodeSockJsPayloads(raw) {
  const text = typeof raw === 'string' ? raw : `${raw}`;
  if (!text) {
    return [];
  }

  // SockJS control frames
  if (text === 'o' || text === 'h') {
    return [];
  }

  // SockJS message frame: a["...","..."]
  if (text.startsWith('a')) {
    try {
      const arr = JSON.parse(text.slice(1));
      return Array.isArray(arr) ? arr : [];
    } catch (_) {
      return [];
    }
  }

  // SockJS close frame: c[code,"reason"]
  if (text.startsWith('c')) {
    return [];
  }

  // fallback: raw websocket endpoint일 때는 본문 그대로 사용
  return [text];
}

function buildStompFrame(command, headers = {}, body = '') {
  let frame = `${command}\n`;
  for (const [key, value] of Object.entries(headers)) {
    frame += `${key}:${value}\n`;
  }
  frame += '\n';
  if (body) {
    frame += body;
  }
  frame += '\u0000';
  return frame;
}

function parseStompFrame(rawFrame) {
  const separatorIndex = rawFrame.indexOf('\n\n');
  const headerPart = separatorIndex >= 0 ? rawFrame.slice(0, separatorIndex) : rawFrame;
  const bodyPart = separatorIndex >= 0 ? rawFrame.slice(separatorIndex + 2) : '';
  const lines = headerPart.split('\n').filter((line) => line.length > 0);

  if (lines.length === 0) {
    return null;
  }

  const command = lines[0].trim();
  if (!command) {
    return null;
  }

  const headers = {};
  for (let i = 1; i < lines.length; i += 1) {
    const line = lines[i];
    const idx = line.indexOf(':');
    if (idx <= 0) {
      continue;
    }
    const key = line.slice(0, idx);
    const value = line.slice(idx + 1);
    headers[key] = value;
  }

  return { command, headers, body: bodyPart };
}

function parseStompFrames(data) {
  const text = typeof data === 'string' ? data : `${data}`;
  if (!text || text === '\n') {
    return [];
  }

  return text
    .split('\u0000')
    .map((frame) => frame.trimEnd())
    .filter((frame) => frame.trim().length > 0)
    .map(parseStompFrame)
    .filter((frame) => frame !== null);
}

function sendProtocolMessage(socket, payload) {
  if (WS_USE_SOCKJS) {
    socket.send(encodeSockJsPayload(payload));
    return;
  }
  socket.send(payload);
}

/**
 * WebSocket 채팅방 연결 및 메시지 송수신
 *
 * @param {string} token - 인증 토큰
 * @param {number} roomId - 채팅방 ID
 * @param {object} options - 테스트 옵션
 * @param {number} options.duration - 연결 유지 시간 (초)
 * @param {number} options.messageCount - 전송할 메시지 수
 * @param {number} options.messageInterval - 메시지 전송 간격 (초)
 * @returns {object} 테스트 결과
 */
export function connectWebSocketChat(
  token,
  roomId,
  { duration = 60, messageCount = 10, messageInterval = 2 } = {}
) {
  const url = getWebSocketUrl(
    WS_USE_SOCKJS ? buildSockJsWebSocketPath() : STOMP_ENDPOINT_PREFIX
  );
  const params = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    tags: { name: 'websocket_chat' },
  };

  const result = {
    connected: false,
    stompConnected: false,
    httpStatus: null,
    messagesSent: 0,
    messagesReceived: 0,
    errors: [],
  };

  const connectionStart = Date.now();
  let messageIndex = 0;

  const res = ws.connect(url, params, function (socket) {
    wsMetrics.activeConnections.add(1);

    socket.on('open', function () {
      // STOMP CONNECT는 HTTP 헤더가 아니라 프레임 헤더에서 Authorization을 읽는다.
      const connectFrame = buildStompFrame('CONNECT', {
        'accept-version': '1.2',
        'heart-beat': '10000,10000',
        Authorization: `Bearer ${token}`,
      });
      sendProtocolMessage(socket, connectFrame);
      console.log(`[WS] TCP 연결 완료, STOMP CONNECT 전송: roomId=${roomId}`);

      // CONNECTED 프레임이 일정 시간 안에 오지 않으면 실패로 처리한다.
      socket.setTimeout(function () {
        if (result.stompConnected) {
          return;
        }
        const message = `STOMP CONNECT timeout (${STOMP_CONNECT_TIMEOUT_MS}ms): roomId=${roomId}`;
        console.error(`[WS] ${message}`);
        result.errors.push(message);
        wsMetrics.errorRate.add(1);
        socket.close();
      }, STOMP_CONNECT_TIMEOUT_MS);
    });

    socket.on('message', function (raw) {
      const payloads = WS_USE_SOCKJS ? decodeSockJsPayloads(raw) : [raw];
      for (const payload of payloads) {
        const frames = parseStompFrames(payload);
        for (const frame of frames) {
        if (frame.command === 'CONNECTED') {
          if (result.stompConnected) {
            continue;
          }

          result.stompConnected = true;
          result.connected = true;
          const connectionDuration = Date.now() - connectionStart;
          wsMetrics.connectionTime.add(connectionDuration);

          console.log(`[WS] STOMP 연결 성공: roomId=${roomId}, duration=${connectionDuration}ms`);

          const subscribeFrame = buildStompFrame('SUBSCRIBE', {
            id: `sub-${roomId}`,
            destination: `${STOMP_TOPIC_PREFIX}${roomId}`,
          });
          sendProtocolMessage(socket, subscribeFrame);

          socket.setInterval(function () {
            if (!result.stompConnected) {
              return;
            }

            if (messageIndex >= messageCount) {
              socket.close();
              return;
            }

            const messageBody = JSON.stringify({
              roomId,
              type: 'TEXT',
              content: `k6 WebSocket 테스트 메시지 ${messageIndex + 1}/${messageCount}`,
              s3Key: null,
            });

            const sendStart = Date.now();
            sendProtocolMessage(
              socket,
              buildStompFrame(
                'SEND',
                {
                  destination: STOMP_APP_DESTINATION,
                  'content-type': 'application/json',
                },
                messageBody
              )
            );
            wsMetrics.messageSendTime.add(Date.now() - sendStart);
            wsMetrics.messagesSent.add(1);
            result.messagesSent += 1;
            messageIndex += 1;

            console.log(`[WS] 메시지 전송: ${messageIndex}/${messageCount}`);
          }, messageInterval * 1000);

          socket.setTimeout(function () {
            console.log(`[WS] 최대 연결 시간 도달: ${duration}초`);
            socket.close();
          }, duration * 1000);
        } else if (frame.command === 'MESSAGE') {
          const receiveTime = Date.now();
          wsMetrics.messagesReceived.add(1);
          result.messagesReceived += 1;

          try {
            const message = JSON.parse(frame.body || '{}');
            wsMetrics.messageReceiveTime.add(Date.now() - receiveTime);

            check(message, {
              'Message has messageId': (msg) => msg.messageId !== undefined,
              'Message has type': (msg) => msg.type !== undefined,
            });
          } catch (error) {
            result.errors.push(`메시지 파싱 실패: ${error.message}`);
            wsMetrics.errorRate.add(1);
          }
        } else if (frame.command === 'ERROR') {
          const errorMessage = frame.headers?.message || frame.body || 'STOMP ERROR';
          console.error(`[WS] STOMP 에러: ${errorMessage}`);
          result.errors.push(errorMessage);
          wsMetrics.errorRate.add(1);
          socket.close();
        } else {
          // HEARTBEAT/RECEIPT 등은 부하 테스트 메트릭 집계에서 제외
          continue;
        }
      }
      }
    });

    socket.on('close', function () {
      console.log(`[WS] 연결 종료: roomId=${roomId}`);
      wsMetrics.activeConnections.add(-1);

      if (!result.stompConnected) {
        const message = `WebSocket closed before STOMP CONNECTED: roomId=${roomId}`;
        if (!result.errors.includes(message)) {
          result.errors.push(message);
          wsMetrics.errorRate.add(1);
        }
      }
    });

    socket.on('error', function (e) {
      const errorMessage = e && typeof e.error === 'function' ? e.error() : 'WebSocket error';
      console.error(`[WS] 에러: ${errorMessage}`);
      result.errors.push(errorMessage);
      wsMetrics.errorRate.add(1);
    });
  });

  check(res, {
    'WebSocket status is 101': (r) => r && r.status === 101,
  });

  result.httpStatus = res && typeof res.status === 'number' ? res.status : null;
  if (!res || res.status !== 101) {
    const message = `WebSocket upgrade failed: status=${result.httpStatus ?? 'unknown'} url=${url}`;
    console.error(`[WS] ${message}`);
    result.errors.push(message);
    wsMetrics.errorRate.add(1);
  }

  wsMetrics.errorRate.add(result.errors.length > 0 ? 1 : 0);

  return result;
}

/**
 * WebSocket 연결 안정성 테스트
 * 장시간 연결을 유지하면서 주기적으로 메시지를 보내 안정성을 확인
 *
 * @param {string} token - 인증 토큰
 * @param {number} roomId - 채팅방 ID
 * @param {number} durationMinutes - 테스트 지속 시간 (분)
 */
export function stabilityTest(token, roomId, durationMinutes = 10) {
  const durationSeconds = durationMinutes * 60;
  const messageInterval = 30; // 30초마다 메시지 전송
  const messageCount = Math.floor(durationSeconds / messageInterval);

  return connectWebSocketChat(token, roomId, {
    duration: durationSeconds,
    messageCount,
    messageInterval,
  });
}
