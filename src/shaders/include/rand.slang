float rand(float2 co) {
   float2 K1 = {
        23.14069263277926, // e^pi (Gelfond's constant)
         2.665144142690225 // 2^sqrt(2) (Gelfond–Schneider constant)
    };
    return fract(cos(dot(co, K1)) * 12345.6789 );
}

float3 rand3(float2 co) {
    return float3(rand(co), rand(co + 1.0), rand(co + 2.0));
}

float3 randFloatOnHemisphere(float2 co, float3 norm) {
    float3 u = rand3(co);
    if (dot(u, norm) < 0.0) {
        u = -u;
    }
    return u;
}