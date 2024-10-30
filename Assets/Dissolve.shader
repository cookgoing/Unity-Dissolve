Shader "Unlit/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		iChannel0("Noise Texture", 2D) = "noise" {}
		iChannel1("Primary Albedo", 2D) = "primary" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                // UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			sampler2D iChannel0;
			sampler2D iChannel1;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv.xy;
				float3 col = float3(0., 0., 0.);
				float3 heightmap = tex2D(iChannel0, uv).rrr;
				float3 background = tex2D(iChannel1, uv).rgb;
				float3 foreground = float3(0., 0., 0.); // for now just make it white

				float t = frac(-_Time.y*0.1);// t: （1 -> 0）
				float3 erosion = smoothstep(t - .2, t + 0.0, heightmap); // erosion: 越来越大。t:（-0.2，0） - （0.8，1）; 透明的地方（a == 0）, 0->1；不透明的地方, （0 -> 1, 但是比更透明的地方早变化）
				float3 border = smoothstep(0., 1., erosion) - smoothstep(.1, 1., erosion);//（0 -> 0.1 -> 0）, 越透明的地方越晚经历这个步骤
				// 这是一句很关键的代码，因为(0 -> 0.1 -> 0), 所以才能表示出被火焰燃烧的纹路（return float4(border, 1.0)）。越是不透明的地方越会先经历，所以先被烧，越是透明的地方，越后被烧。

				col = (1. - erosion)*foreground + erosion * background;

				float3 leadcol = float3(1., .5, .1);
				float3 trailcol = float3(0.2, .4, .1);
				float3 fire = lerp(leadcol, trailcol, smoothstep(0.8, 1., border))*2.;

				float3 a = border * fire;

				col += border * fire;
				return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
