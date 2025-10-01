struct Interval {
      float tMin;
      float tMax;

      float size() {
          return tMax - tMin;
      }

      bool contains(float x) {
          return x >= tMin && x <= tMax;
      }

      bool surrounds(float x) {
          return x > tMin && x < tMax;
      }

      float clamp(float x) {
          return clamp(x, tMin, tMax);
      }

      static const Interval empty = Interval(1.#INF, -1.#INF);
      static const Interval universe = Interval(-1.#INF, 1.#INF);
};

float3 reflect(float3 v, float3 n) {
    return v - 2.0 * dot(v, n) * n;
}

float3 refract(float3 uv, float3 n, float etaiOverEtat) {
    float cosTheta = min(dot(-uv, n), 1.0);
    float3 rOutPerp = etaiOverEtat * (uv + cosTheta * n);
    float3 rOutParallel = -sqrt(abs(1.0 - dot(rOutPerp, rOutPerp))) * n;
    return rOutPerp + rOutParallel;
}
