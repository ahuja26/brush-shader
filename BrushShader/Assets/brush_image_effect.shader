//shader adapted from http://majdakar.blogspot.com/2011/10/techy-stuff-shader.html
//how to grab depth buffer in unity: http://willychyr.com/2013/11/unity-shaders-depth-and-normal-textures/

Shader "Custom/brush_image_effect" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BrushTex ("Brush (RGB)", 2D) = "white" {}
	}
	SubShader {
		Pass
		{
		CGPROGRAM
		#pragma target 3.0
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		
		struct appdata{
			half4 vertex:POSITION;
			float2 texcoord:TEXCOORD0;
			half4 texcoord1:TEXCOORD1;
		};
		
		struct v2f{
			half4 pos:SV_POSITION;
			float2 uv:TEXCOORD0;
			half4 scrPos:TEXCOORD1;
		};
		
		uniform sampler2D _MainTex;
		uniform sampler2D _BrushTex;
		sampler2D _CameraDepthTexture;
		
		//vertex shader
		v2f vert(appdata v) {
		v2f outVert;
		outVert.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		outVert.uv = MultiplyUV( UNITY_MATRIX_TEXTURE0, v.texcoord );
		outVert.uv.xy=v.texcoord.xy;
		outVert.scrPos=ComputeScreenPos(outVert.pos);
		outVert.scrPos.y=1-outVert.scrPos.y;
		return outVert;
		}
	
		//distortion magnitude
		float d_mag=0.05;
		
		//fragment shader
		half4 frag(v2f i) : COLOR
		{
			half4 color;
			half3 color_offset;
			
			half3 brushValue;
			half3 bTex = tex2D(_BrushTex,i.uv.xy).rgb;
			//depth of current fragment
			float depthVal = 1.0 - smoothstep( 0.998, 1.0, Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r));
			//find depths of neighboring fragments
			float depthValOffset1 = 1.0 - smoothstep( 0.998, 1.0, Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)+half4(-d_mag,-d_mag,0,0)).r));
			float depthValOffset2 = 1.0 - smoothstep( 0.998, 1.0, Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)+half4(d_mag,-d_mag,0,0)).r));
			float depthValOffset3 = 1.0 - smoothstep( 0.998, 1.0, Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)+half4(-d_mag,d_mag,0,0)).r));
			float depthValOffset4 = 1.0 - smoothstep( 0.998, 1.0, Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)+half4(d_mag,d_mag,0,0)).r));
			
			float depthMax = max( max( max( depthValOffset4, depthValOffset3 ), depthValOffset2 ), depthValOffset1 );
			
			brushValue =  tex2D(_BrushTex, i.uv.xy - float2(-d_mag,-d_mag) ).rgb; 
  			color_offset = tex2D(_MainTex, i.uv.xy + (-0.5+brushValue.r)*float2( -d_mag, -d_mag)).rgb;
			//distortion depends on depth
			d_mag=0.02*(1.0-1.5*depthVal);
			
			half3 brushValue4 =  tex2D(_BrushTex, i.uv.xy - float2(-d_mag,-d_mag) ).rgb; 
  			half3 color_offset4 = tex2D(_MainTex, i.uv.xy + (-0.5+brushValue.r)*float2( -d_mag, -d_mag)).rgb;
  			half3 brushValue3 =  tex2D(_BrushTex, i.uv.xy - float2(d_mag,-d_mag) ).rgb; 
  			half3 color_offset3 = tex2D(_MainTex, i.uv.xy + (-0.5+brushValue.r)*float2( d_mag, -d_mag)).rgb;
			half3 brushValue2 =  tex2D(_BrushTex, i.uv.xy - float2(-d_mag,d_mag) ).rgb; 
  			half3 color_offset2 = tex2D(_MainTex, i.uv.xy + (-0.5+brushValue.r)*float2( -d_mag, d_mag)).rgb;
			half3 brushValue1 =  tex2D(_BrushTex, i.uv.xy - float2(d_mag,d_mag) ).rgb; 
  			half3 color_offset1 = tex2D(_MainTex, i.uv.xy + (-0.5+brushValue.r)*float2( d_mag, d_mag)).rgb;
			
			//smudge in opposite direction of greatest depth difference
			if(depthValOffset4 == depthMax)
			{
			brushValue=brushValue4;
			color_offset=color_offset4;
			}
			if(depthValOffset3 == depthMax)
			{
			brushValue=brushValue3;
			color_offset=color_offset3;
			}
			if(depthValOffset2 == depthMax)
			{
			brushValue=brushValue2;
			color_offset=color_offset2;
			}
			if(depthValOffset1 == depthMax)
			{
			brushValue=brushValue1;
			color_offset=color_offset1;
			}
			//vignette
			float dist = distance(i.uv.xy, float2(0.5,0.5));
  			float b1 = smoothstep(0.9, 0.1, dist);
  			float b = 0.4 *b1;
  
			//color correction
			float mr = smoothstep( 0.0, (0.95), color_offset.r );
  			float mg = smoothstep( 0.0, (0.95), color_offset.g );
  			float mb = smoothstep( 0.0, (0.95), color_offset.b );
  			//green channel of brush texture is used to mark areas that are not to be painted
			half3 col1=b1*(half3(mr,mg,mb) + 0.05*half3(bTex.r,bTex.r,bTex.r));
			color = half4( col1, (1.0-bTex.g));
			return color;
		}
		ENDCG
		}
	} 
}
