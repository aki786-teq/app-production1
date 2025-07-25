import { Controller } from "@hotwired/stimulus";
import { Pose } from "@mediapipe/pose";

export default class extends Controller {
  static targets = ["image", "height", "message", "imageError", "heightError"];

  connect() {
    this.clearErrors();
    this.messageTarget.textContent = "";
  }

  clearErrors() {
    if (this.hasImageErrorTarget) this.imageErrorTarget.textContent = "";
    if (this.hasHeightErrorTarget) this.heightErrorTarget.textContent = "";
    if (this.hasMessageTarget) this.messageTarget.textContent = "";
  }

  async submit(event) {
    event.preventDefault();
    this.clearErrors();

    const file = this.imageTarget.files[0];
    const heightCm = parseFloat(this.heightTarget.value);

    let hasError = false;

    if (!file) {
      this.imageErrorTarget.textContent = "画像を選択してください。";
      hasError = true;
    }

    if (!heightCm || heightCm < 50 || heightCm > 250) {
      this.heightErrorTarget.textContent = "有効な身長を入力してください（50〜250cm）。";
      hasError = true;
    }

    if (hasError) return;

    try {
      const distanceCm = await this.processImage(file, heightCm);

      if (typeof distanceCm !== "number") {
        this.messageTarget.textContent = "解析に失敗しました。";
        return;
      }

      this.sendResult(distanceCm, heightCm);
    } catch (err) {
      console.error(err);
      this.messageTarget.textContent = "エラーが発生しました。";
    }
  }

  async processImage(file, userHeight) {
    const imageBitmap = await createImageBitmap(file);
    const canvas = document.getElementById("pose-canvas");
    canvas.width = imageBitmap.width;
    canvas.height = imageBitmap.height;

    const ctx = canvas.getContext("2d");
    ctx.drawImage(imageBitmap, 0, 0);

    return new Promise((resolve, reject) => {
      const pose = new Pose({
        locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/pose/${file}`,
      });

      pose.setOptions({
        modelComplexity: 1,
        smoothLandmarks: true,
        enableSegmentation: false,
        minDetectionConfidence: 0.5,
        minTrackingConfidence: 0.5
      });

      pose.onResults((results) => {
  const lm = results.poseLandmarks;
  if (!lm) {
    reject("ランドマーク検出失敗");
    return;
  }

  const imageHeightPx = canvas.height;

  function getDistance(a, b) {
  return Math.sqrt(
    Math.pow(a.x - b.x, 2) +
    Math.pow(a.y - b.y, 2)
  );
}

  function getMidpoint(a, b) {
  return {
    x: (a.x + b.x) / 2,
    y: (a.y + b.y) / 2
  };
}

  const eye = getMidpoint(lm[2], lm[5]);
  const hip = getMidpoint(lm[23], lm[24]);
  const heel = getMidpoint(lm[29], lm[30]);
  const pinky = lm[17] || lm[18];

  if (!eye || !hip || !heel || !pinky) {
    reject("必要なランドマークが不足");
    return;
  }

  // 「目→腰→踵」の2本の斜め距離（正規化）
  const eyeToHip = getDistance(eye, hip);
  const hipToHeel = getDistance(hip, heel);
  const totalNormDistance = eyeToHip + hipToHeel;
  const totalPxDistance = totalNormDistance * imageHeightPx;

  // 実際の「目→踵」距離 = 身長 - 5cm
  const actualEyeToHeelCm = userHeight - 5;

  // px → cm 変換係数
  const pxToCm = actualEyeToHeelCm / totalPxDistance;

  // 小指→踵のピクセル距離をcmに換算して4cm引く（中指補正）
  const deltaYPx = (heel.y - pinky.y) * imageHeightPx;
  const distanceCm = Math.max((deltaYPx * pxToCm) - 4, 0);

  resolve(parseFloat(distanceCm.toFixed(2)));
});

      pose.send({ image: canvas });
    });
  }

  sendResult(distanceCm, heightCm) {
  fetch("/stretch_distances/analyze", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({
      stretch_distance: {
        distance_cm: distanceCm,
        height_cm: heightCm
      }
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      window.location.href = data.result_url;
    } else {
      if (data.errors.image) {
        this.imageErrorTarget.textContent = data.errors.image.join(", ");
      }
      if (data.errors.height_cm) {
        this.heightErrorTarget.textContent = data.errors.height_cm.join(", ");
      }
      if (!data.errors.image && !data.errors.height_cm) {
        this.messageTarget.textContent = data.errors.join(", ");
      }
    }
  })
  .catch(error => {
    console.error("通信エラー:", error);
    this.messageTarget.textContent = "通信エラーが発生しました。";
  });
}
}
