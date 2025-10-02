import "constants.slang";
import "material.slang";
import "ray.slang";
import "util.slang";

interface Hittable {
    Optional<Hit> hit(in Ray ray, Interval interval);
}

struct Sphere : Hittable {
    float3 center;
    float radius;
    Material mat;

    __init(float3 center, float radius, Material mat) {
        this.center = center;
        this.radius = max(0.0, radius);
        this.mat = mat;
    }

    float2 getUv(float3 p) {
        // p: a given point on the sphere of radius one, centered at the origin.
        // u: returned value [0,1] of angle around the Y axis from X=-1.
        // v: returned value [0,1] of angle from Y=-1 to Y=+1.
        float theta = acos(-p.y);
        float phi = atan2(-p.z, p.x) + PI;
        float u = phi / TAU;
        float v = theta / PI;
        return float2(u, v);
    }

    Optional<Hit> hit(in Ray ray, Interval interval) {
        float3 oc = center - ray.origin;

        float a = dot(ray.dir, ray.dir);
        float h = dot(ray.dir, oc);
        float c = dot(oc, oc) - radius * radius;
        float discriminant = h * h - a * c;
        if (discriminant < 0) {
            return none;
        } else {
            float sqrtDistc = sqrt(discriminant);
            float root = (h - sqrt(discriminant)) / a;

            if (!interval.surrounds(root)) {
                root = (h + sqrtDistc) / a;
                if (!interval.surrounds(root)) {
                    return none;
                }
            }

            float3 point = ray.at(root);
            float3 normal = (point - center) / radius;

            float2 uv = getUv(normal);

            Hit hit = Hit(point, normal, root, uv, mat, ray);

            return hit;
        }
    }
}

struct Quad : Hittable {
    float3 q;
    float3 u;
    float3 v;
    float3 normal;
    float d;
    float3 w;

    Material mat;

    __init(float3 q, float3 u, float3 v, Material mat) {
        this.q = q;
        this.u = u;
        this.v = v;
        this.mat = mat;

        float3 n = cross(u, v);
        this.normal = normalize(n);

        this.d = dot(normal, q);

        this.w = n / dot(n, n);
    }

    Optional<float2> isInside(float a, float b) {
        Interval unitInterval = Interval(0.0, 1.0);

        if (!unitInterval.contains(a) || !unitInterval.contains(b)) {
            return none;
        }

        return float2(a, b);
    }

    Optional<Hit> hit(in Ray ray, Interval interval) {
        let denom = dot(normal, ray.dir);

        if (abs(denom) < 1e-8) {
            // Parallel to the plane
            return none;
        }

        float t = (d - dot(normal, ray.origin)) / denom;

        if (!interval.contains(t)) {
            // Outside the ray interval
            return none;
        }

        float3 intersection = ray.at(t);
        float3 planarHit = intersection - q;
        let alpha = dot(w, cross(planarHit, v));
        let beta = dot(w, cross(u, planarHit));

        if (let uv = isInside(alpha, beta)) {
            return Hit(intersection, normal, t, uv, mat, ray);
        }

        return none;
    }
};

struct Box : Hittable {
    Quad front;
    Quad right;
    Quad back;
    Quad left;
    Quad top;
    Quad bottom;

    __init(float3 a, float3 b, Material mat) {
        let min = float3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z));
        let max = float3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z));

        let dx = float3(max.x - min.x, 0, 0);
        let dy = float3(0, max.y - min.y, 0);
        let dz = float3(0, 0, max.z - min.z);

        front = Quad(float3(min.x, min.y, max.z), dx, dy, mat); // Front
        right = Quad(float3(max.x, min.y, max.z), -dz, dy, mat); // Right
        back = Quad(float3(max.x, min.y, min.z), -dx, dy, mat); // Back
        left = Quad(float3(min.x, min.y, min.z), dz, dy, mat);  // Left
        top = Quad(float3(min.x, max.y, max.z), dx, -dz, mat); // Top
        bottom = Quad(float3(min.x, min.y, min.z), dx, dz, mat);  // Bottom
    }

    void sideHit(in Quad side, inout Optional<Hit> closest, in Ray ray, in Interval interval) {
      if (let hit = side.hit(ray, interval)) {
          if (closest.hasValue) {
              if (hit.t <= closest.value.t) {
                  closest = hit;
              }
          } else {
              closest = hit;
          }
      }
    }

    Optional<Hit> hit(in Ray ray, Interval interval) {
        Optional<Hit> closestHit = none;
        sideHit(front, closestHit, ray, interval);
        sideHit(right, closestHit, ray, interval);
        sideHit(back, closestHit, ray, interval);
        sideHit(left, closestHit, ray, interval);
        sideHit(top, closestHit, ray, interval);
        sideHit(bottom, closestHit, ray, interval);
        return closestHit;
    }
};