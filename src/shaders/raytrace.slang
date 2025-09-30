import "./include/uv.slang";

struct Params {
    double2 resolution;
};

layout(location = 0) ConstantBuffer<Params> params;

struct VOut {
    float4 position : SV_Position;
    float2 uv;
    float2 ndc;
    nointerpolation double aspect;
    nointerpolation double2 pixelDelta;
};


[shader("vertex")]
VOut vert(BasicVIn i) {
    BasicVOut o = basicVertex(i);
    VOut v;
    v.position = o.position;
    v.uv = o.uv;

    v.ndc = (v.uv + 1.0) / 2.0;

    v.aspect = params.resolution.x / params.resolution.y;

    v.pixelDelta = 1.0 / params.resolution;

    return v;
}

struct Ray {
    double3 origin;
    double3 dir;

    double3 at(double t) {
        return origin + t * dir;
    }

    double hitSphere(float3 center, double radius) {
        double3 cameraOffset = center - origin;

        double dirLenSq = dot(dir, dir);
        double h = dot(dir, cameraOffset);
        double c = dot(cameraOffset, cameraOffset) - radius * radius;
        double discriminant = h * h - dirLenSq * c;
        if (discriminant < 0) {
            return -1.0;
        } else {
            return (h - sqrt(discriminant)) / dirLenSq;
        }
    }
}



[shader("fragment")]
float4 frag(VOut i) : SV_Target {
    float4 hitColor = float4(0, 0, 0, 1);

    double2 adjustedUv = double2(i.uv * 2.0 - 1.0);
    adjustedUv.x *= i.aspect;

    Ray ray;
    ray.origin = double3(0, 0, 0);
    ray.dir = double3(adjustedUv, 1.0);

    double t = ray.hitSphere(float3(0, 0, -1), 0.5);
    if (t > 0.0) {
        let normal = normalize(ray.at(t) - double3(0, 0, -1));
        return 0.5 * float4(normal + 1.0, 1.0);
    }

    return lerp(float4(0.3, 0.5, 1.0, 1.0), float4(1.0), 1.0 - i.ndc.y);
}