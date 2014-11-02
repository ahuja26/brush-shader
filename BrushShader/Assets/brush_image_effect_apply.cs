//how to grab depth buffer in unity: http://willychyr.com/2013/11/unity-shaders-depth-and-normal-textures/
using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class brush_image_effect_apply : MonoBehaviour
{

	#region Variables
		public Shader BrushEffect;
		private Material material1;
	#endregion
	
	#region Properties
		Material material {
				get {
						if (material1 == null) {
								material1 = new Material (BrushEffect);
								material1.hideFlags = HideFlags.HideAndDontSave;
						}
						return material1;
				}
		}
	#endregion
		// Use this for initialization
		void Start ()
		{
				if (!SystemInfo.supportsImageEffects) {
						enabled = false;
						return;
				}
				//get depth texture here
				camera.depthTextureMode = DepthTextureMode.Depth;
		}
	
		void OnRenderImage (RenderTexture sourceTexture, RenderTexture destTexture)
		{
				if (BrushEffect != null) {
						Graphics.Blit (sourceTexture, destTexture, material);
				} else {
						Graphics.Blit (sourceTexture, destTexture);
				}
		}

		void OnDisable ()
		{
				if (material1) {
						DestroyImmediate (material1);
				}
		}
}
