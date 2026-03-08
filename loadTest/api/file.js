/**
 * 파일 API
 *
 * 커버하는 엔드포인트:
 *   POST /api/files/presigned              Presigned URL 생성
 *   POST /api/files                        파일 첨부 정보 저장
 *   DELETE /api/files/{fileId}             파일 삭제
 *
 * 이미지 첨부 워크플로우:
 *   1. generatePresignedUrl() - S3 업로드용 Presigned URL 받기
 *   2. uploadToS3() - Presigned URL로 실제 파일 업로드
 *   3. saveFileAttachment() - 파일 메타데이터 저장 및 fileId 받기
 *   4. createPost()에 fileIds 전달하여 게시글 작성
 */

import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL, headers } from '../lib/config.js';
import { record } from '../lib/helpers.js';
import { getRandomImage } from '../lib/image-loader.js';

/**
 * POST /api/files/presigned
 * S3 업로드용 Presigned URL을 생성합니다.
 *
 * @param {string} token - 인증 토큰
 * @param {string} fileName - 파일명 (예: "test-image.jpg")
 * @param {string} mimeType - MIME 타입 (예: "image/jpeg")
 * @returns {{ presignedUrl: string, s3Key: string } | null} Presigned URL과 S3 키
 */
export function generatePresignedUrl(token, fileName, mimeType) {
  const res = http.post(
    `${BASE_URL}/api/files/presigned`,
    JSON.stringify({ fileName, mimeType }),
    {
      headers: headers(true, token),
      tags: { name: 'file_presigned' },
    }
  );

  record(res, 'POST /api/files/presigned', {
    'presigned url: status 200': (r) => r.status === 200,
  });

  try {
    const body = JSON.parse(res.body);
    return body?.data ?? null;
  } catch (_) {
    return null;
  }
}

/**
 * S3에 실제 파일을 업로드합니다.
 *
 * @param {string} presignedUrl - S3 Presigned URL
 * @param {ArrayBuffer} fileData - 업로드할 파일 데이터 (바이너리)
 * @param {string} mimeType - MIME 타입
 * @returns {boolean} 업로드 성공 여부
 */
export function uploadToS3(presignedUrl, fileData, mimeType = 'image/jpeg') {
  const res = http.put(presignedUrl, fileData, {
    headers: {
      'Content-Type': mimeType,
    },
    tags: { name: 's3_upload' },
  });

  const success = check(res, {
    's3 upload: status 200': (r) => r.status === 200,
  });

  return success;
}

/**
 * POST /api/files
 * 파일 메타데이터를 저장하고 fileId를 받습니다.
 *
 * @param {string} token - 인증 토큰
 * @param {object} params - 파일 정보
 * @param {string} params.originalName - 원본 파일명
 * @param {string} params.s3Key - S3 키
 * @param {string} params.mimeType - MIME 타입
 * @param {string} params.category - 파일 카테고리 (RESUME|PORTFOLIO|JOB_POSTING|AI_CHAT_ATTACHMENT)
 * @param {number} params.fileSize - 파일 크기 (바이트)
 * @param {string} params.refType - 참조 타입 (USER|CHATROOM|POST|AI_CHAT)
 * @param {number} params.refId - 참조 ID (없으면 null)
 * @param {number} params.sortOrder - 정렬 순서 (기본: 0)
 * @returns {number|null} 생성된 fileId
 */
export function saveFileAttachment(token, {
  originalName,
  s3Key,
  mimeType,
  category = null,
  fileSize,
  refType,
  refId = null,
  sortOrder = 0,
}) {
  const body = {
    originalName,
    s3Key,
    mimeType,
    fileSize,
    refType,
    sortOrder,
  };

  if (category !== null && category !== undefined) {
    body.category = category;
  }

  // refId가 있으면 포함
  if (refId !== null) {
    body.refId = refId;
  }

  const res = http.post(
    `${BASE_URL}/api/files`,
    JSON.stringify(body),
    {
      headers: headers(true, token),
      tags: { name: 'file_save' },
    }
  );

  record(res, 'POST /api/files', {
    'save file: status 201': (r) => r.status === 201,
  });

  try {
    return JSON.parse(res.body)?.data?.fileId ?? null;
  } catch (_) {
    return null;
  }
}

/**
 * DELETE /api/files/{fileId}
 * 파일을 삭제합니다.
 *
 * @param {string} token - 인증 토큰
 * @param {number} fileId - 파일 ID
 */
export function deleteFile(token, fileId) {
  const res = http.del(`${BASE_URL}/api/files/${fileId}`, null, {
    headers: headers(true, token),
    tags: { name: 'file_delete' },
  });

  record(res, `DELETE /api/files/${fileId}`, {
    'delete file: status 204': (r) => r.status === 204,
  });
}

/**
 * 게시글용 이미지 첨부 헬퍼 함수
 * fixtures/images/ 폴더의 랜덤 이미지를 선택하여 업로드합니다.
 * Presigned URL 생성 → S3 업로드 → 메타데이터 저장을 한번에 처리합니다.
 *
 * @param {string} token - 인증 토큰
 * @returns {number|null} 생성된 fileId
 */
export function attachImageForPost(token) {
  // 1. 랜덤 이미지 선택
  const image = getRandomImage();
  const { fileName, fileData, fileSize, mimeType } = image;

  // 2. Presigned URL 생성
  const presignedData = generatePresignedUrl(token, fileName, mimeType);
  if (!presignedData) {
    console.error('Failed to generate presigned URL');
    return null;
  }

  const { presignedUrl, s3Key } = presignedData;

  // 3. S3에 업로드
  const uploadSuccess = uploadToS3(presignedUrl, fileData, mimeType);
  if (!uploadSuccess) {
    console.error('Failed to upload to S3');
    return null;
  }

  // 4. 파일 메타데이터 저장
  const fileId = saveFileAttachment(token, {
    originalName: fileName,
    s3Key,
    mimeType,
    category: null,
    fileSize,
    refType: 'POST',
    refId: null,  // 게시글 작성 전이므로 null
    sortOrder: 0,
  });

  return fileId;
}
