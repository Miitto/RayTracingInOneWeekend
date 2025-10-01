
struct Ray {
    float3 origin;
    float3 dir;

    float3 at(float t) {
        return origin + t * dir;
    }
};

struct Scatter {
    float3 attenuation;
    Ray scattered;
}

interface Material {
    Optional<Scatter> scatter(in Ray ray, in Hit hit);
}

struct Hit {
    float3 point;
    float3 normal;
    float t;
    bool frontFace;

    Material mat;

    __init(float3 point, float3 normal, float t, Material mat, in Ray ray) {
        this.point = point;
        this.t = t;
        this.mat = mat;

        frontFace = dot(ray.dir, normal) < 0;
        this.normal = frontFace ? normal : -normal;
    }
};

