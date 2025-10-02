import "./ray.slang";
import "./rand.slang";

struct Lambertian : Material {
    float3 albedo;

    __init(float3 albedo) {
        this.albedo = albedo;
    }

    Optional<Scatter> scatter(in Ray ray, in Hit hit, float2 uv) {
        float2 seed = hit.point.xy + hit.point.zx + uv;
        float3 scatterDir = hit.normal + normalize(rand3(seed));

        // Catch degenerate scatter direction
        if (dot(scatterDir, scatterDir) < 1e-8) {
            scatterDir = hit.normal;
        }
        
        let scattered = Ray(hit.point, scatterDir);
        let attenuation = albedo;
        return Scatter(attenuation, scattered);
    }
};

struct Metal : Material {
    float3 albedo;
    float fuzz;

    __init(float3 albedo, float fuzz) {
        this.albedo = albedo;
        this.fuzz = clamp(fuzz, 0.0, 1.0);
    }

    Optional<Scatter> scatter(in Ray ray, in Hit hit, float2 uv) {
        float3 reflected = float3(normalize(reflect(normalize(ray.dir), hit.normal)));
        float2 seed = float2(hit.point.xy + hit.point.zx) + uv;
        let scattered = Ray(hit.point, reflected + fuzz * rand3(seed));
        let attenuation = albedo;
        if (dot(scattered.dir, hit.normal) > 0.0) {
            return Scatter(attenuation, scattered);
        } else {
            return none;
        }
    }
};

struct Dielectric : Material {
    float ir; // Index of Refraction

    __init(float indexOfRefraction) {
        this.ir = indexOfRefraction;
    }

    static float reflectance(float cosine, float refIdx) {
        // Use Schlick's approximation for reflectance.
        float r0 = (1.0 - refIdx) / (1.0 + refIdx);
        r0 = r0 * r0;
        return r0 + (1.0 - r0) * pow((1.0 - cosine), 5.0);
    }

    Optional<Scatter> scatter(in Ray ray, in Hit hit, float2 uv) {
        let attenuation = float3(1.0, 1.0, 1.0);

        float refractionRatio = hit.frontFace ? (1.0 / ir) : ir;

        float3 unitDir = normalize(ray.dir);

        float cosTheta = min(dot(-unitDir, hit.normal), 1.0);
        float sinTheta = sqrt(1.0 - cosTheta * cosTheta);

        bool cannotRefract = refractionRatio * sinTheta > 1.0;

        float2 seed = float2(hit.point.xy + hit.point.zx) + uv;
        float3 direction;
        if (cannotRefract || reflectance(cosTheta, refractionRatio) > rand(seed)) {
            direction = reflect(unitDir, hit.normal);
        } else {
            direction = refract(unitDir, hit.normal, refractionRatio);
        }
        let scattered = Ray(hit.point, direction);
        return Scatter(attenuation, scattered);
    }
};

struct DiffuseLight : Material {
    float3 emitColor;

    __init(float3 emitColor) {
        this.emitColor = emitColor;
    }

    Optional<Scatter> scatter(in Ray ray, in Hit hit, float2 uv) {
        return none;
    }

    override float3 emitted(float2 uv) {
        return emitColor;
    }
};