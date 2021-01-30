Shader "Unlit/IfsShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        [HDR] _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha One
        LOD 100
        Cull Off
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            #define PI 3.14159265359
            
            float sdRect(float2 p, float2 b)
            {
                float2 d = abs(p) - b;
                return max(d.x, d.y) + min(max(d.x, d.y), 0.0);
            }
            
            float2x2 rot(float x)
            {
                return float2x2(cos(x), sin(x), -sin(x), cos(x));
            }
            
            // https://www.shadertoy.com/view/3tX3R4
            float remap(float val, float im, float ix, float om, float ox)
            {
                return clamp(om + (val - im) * (ox - om) / (ix - im), om, ox);
            }
            
            half3 hsv2rgb(half3 c)
            {
                half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }
            
            float4 _TintColor;
            
            half4 frag(v2f i): SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                half3 col = half3(0.0, 0.0, 0.0);
                
                float2 p = i.uv;
                float2 q = (frac(p) - 0.5) * 5.0;
                float d = 9999.0;
                float z = PI * (_Time.y - 16.0) / 12.0;
                for (int i = 0; i < 5; ++i)
                {
                    q = abs(q) - 0.5;
                    q = mul(rot(0.785398), q);
                    q = abs(q) - 0.5;
                    q = mul(rot(z), q);
                    float k = sdRect(q, float2(0.6, 0.1 + q.x));
                    d = min(d, k);
                }
                float s = remap(_Time.y, 24.0, 32.0, 0.1, 0.8);
                col = hsv2rgb(half3(q.x * 4.0, s, 1.0)) * saturate(-2.0 * d) * _TintColor.rgb;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return half4(col, _TintColor.a);
            }
            ENDCG
            
        }
    }
}
