import { Controller } from "@hotwired/stimulus";
import { Pose } from "@mediapipe/pose";

export default class extends Controller {
  static targets = ["image", "message", "imageError"];

  connect() {
    this.clearErrors();
    this.messageTarget.textContent = "";
  }

  clearErrors() {
    if (this.hasImageErrorTarget) this.imageErrorTarget.textContent = "";
    if (this.hasMessageTarget) this.messageTarget.textContent = "";
  }

  async submit(event) {
    event.preventDefault();
    this.clearErrors();

    const file = this.imageTarget.files[0];

    if (!file) {
      this.imageErrorTarget.textContent = "画像を選択してください。";
      return;
    }

    try {
      const result = await this.processImage(file);

      if (!result) {
        this.messageTarget.textContent = "解析に失敗しました。";
        return;
      }

      this.sendResult(result);
    } catch (err) {
      console.error(err);
      this.messageTarget.textContent = "エラーが発生しました。";
    }
  }

  async processImage(file) {
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
        minTrackingConfidence: 0.5,
      });

      pose.onResults((results) => {
        try {
          const lm = results.poseLandmarks;
          if (!lm) throw new Error("ランドマーク検出失敗");

          const imageHeightPx = canvas.height;

          const leftHeel = lm[29];
          const rightHeel = lm[30];
          const leftPinky = lm[17];
          const rightPinky = lm[18];

          if (!leftHeel || !rightHeel || !leftPinky || !rightPinky) {
            throw new Error("必要なランドマークが不足しています");
          }

          const avgHeelY = (leftHeel.y + rightHeel.y) / 2;
          const avgPinkyY = (leftPinky.y + rightPinky.y) / 2;
          const deltaY = avgHeelY - avgPinkyY;

          console.log("avgHeelY:", avgHeelY);
          console.log("avgPinkyY:", avgPinkyY);

          let flexibilityLevel;
          if (deltaY < 0.1) {
            flexibilityLevel = "excellent";
          } else if (deltaY < 0.15) {
            flexibilityLevel = "good";
          } else if (deltaY < 0.2) {
            flexibilityLevel = "average";
          } else {
            flexibilityLevel = "needs_improvement";
          }

          resolve({ flexibilityLevel });
        } catch (error) {
          reject(error.message);
        } finally {
          pose.close();
        }
      });

      pose.initialize().then(() => {
        pose.send({ image: canvas });
      });
    });
  }

  sendResult(result) {
    fetch("/stretch_distances/analyze", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
      body: JSON.stringify({
        stretch_distance: {
          flexibility_level: result.flexibilityLevel
        }
      }),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.success) {
          window.location.href = data.result_url;
        } else {
          if (data.errors.image) {
            this.imageErrorTarget.textContent = data.errors.image.join(", ");
          } else {
            this.messageTarget.textContent = data.errors.join(", ");
          }
        }
      })
      .catch((error) => {
        console.error("通信エラー:", error);
        this.messageTarget.textContent = "通信エラーが発生しました。";
      });
  }
}
