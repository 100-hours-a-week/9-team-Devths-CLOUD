/**
 * 이미지 로더
 * fixtures/images/ 폴더의 이미지 파일들을 로드합니다.
 *
 * 사용법:
 * 1. fixtures/images/ 폴더에 테스트용 이미지 파일을 추가
 * 2. 아래 IMAGE_FILES 배열에 파일명 추가
 * 3. getRandomImage()로 랜덤 이미지 선택
 */

/**
 * fixtures/images/ 폴더에 추가한 이미지 파일명 목록
 * 이미지를 추가하면 여기에 파일명을 등록하세요.
 */
const IMAGE_FILES = [
  'sample-1.png',
  'sample-2.jpeg'
];

/**
 * 이미지 파일들을 미리 로드 (k6 init context에서 실행)
 */
const images = IMAGE_FILES.map(fileName => {
  try {
    const filePath = `../fixtures/images/${fileName}`;
    const fileData = open(filePath, 'b'); // 'b' = binary mode

    // ArrayBuffer는 length가 아닌 byteLength를 사용한다.
    const fileSize = fileData.byteLength ?? fileData.length ?? 0;

    let mimeType = 'application/octet-stream';
    if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (fileName.toLowerCase().endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (fileName.toLowerCase().endsWith('.webp')) {
      mimeType = 'image/webp';
    }

    return {
      fileName,
      fileData,
      fileSize,
      mimeType,
    };
  } catch (error) {
    console.error(`⚠️  Failed to load image: ${fileName} - ${error.message}`);
    return null;
  }
}).filter(img => img !== null);

/**
 * 로드된 이미지 개수 확인
 */
export function getImageCount() {
  return images.length;
}

/**
 * 랜덤 이미지 선택
 * @returns {{ fileName: string, fileData: ArrayBuffer, fileSize: number, mimeType: string }}
 */
export function getRandomImage() {
  if (images.length === 0) {
    throw new Error('⚠️ 이미지가 없습니다.');
  }

  const index = Math.floor(Math.random() * images.length);
  return images[index];
}

/**
 * 특정 인덱스의 이미지 선택
 * @param {number} index - 이미지 인덱스 (0부터 시작)
 * @returns {{ fileName: string, fileData: ArrayBuffer, fileSize: number, mimeType: string }}
 */
export function getImageByIndex(index) {
  if (images.length === 0) {
    throw new Error('No images loaded.');
  }

  if (index < 0 || index >= images.length) {
    throw new Error(`Invalid index: ${index}. Valid range: 0-${images.length - 1}`);
  }

  return images[index];
}
