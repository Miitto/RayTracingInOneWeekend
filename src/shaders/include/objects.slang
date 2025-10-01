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

            Hit hit = Hit(point, normal, root, mat, ray);

            return hit;
        }
    }
}
