/* ORIGINAL: "Resistance" by Matthias Hurrle – CC-BY 4.0  
URL: https://openprocessing.org/sketch/2626176
Remixed by <Cade Jung>, 2025-05-
Purpose: animated hero background
*/

// Declare global variables for shader, device pixel ratio, and window dimensions
let theShader, dpr = Math.max(1, 0.5*window.devicePixelRatio), ww = window.innerWidth*dpr, wh = window.innerHeight*dpr;

// Define canvas style for responsive display
const canvasStyle = 'width:100%;height:100%;position:absolute;top:0;left:0;z-index:0;'

// Function to handle window resize events
function windowResized() {
	// Update window dimensions with device pixel ratio
	ww = window.innerWidth*dpr; wh = window.innerHeight*dpr;
  // Resize canvas to match new dimensions
  resizeCanvas(ww, wh);
	// Get canvas element and apply responsive styling
	const canvas = document.querySelector('canvas');
	canvas.style = canvasStyle;
}

// Preload function to load shader files before setup
function preload(){
	// Load vertex and fragment shader files
	theShader = loadShader('vert.glsl', 'frag.glsl');
}

// Setup function runs once at the start
function setup() {
  // PERSONAL COMMENT: DECREASED PIXEL DENSITY TO EXPAND THE CANVAS
  pixelDensity(0.8);
  // Create canvas with WEBGL context
  const canvas = createCanvas(ww, wh, WEBGL);
  // Attach canvas to hero container
  canvas.parent('hero-container');
	// Get canvas element and apply responsive styling
	canvas.style = canvasStyle;
}

// Draw function runs continuously
function draw() {
  // Set the shader as the current drawing context
  shader(theShader);
  // Pass resolution uniform to shader
  theShader.setUniform("resolution", [width, height]);
  // PERSONAL COMMENT: SLOWED THE ANIMATION
  theShader.setUniform("time", millis() / 2000);
  // Draw a rectangle that fills the canvas
  rect(0,0,width,height);
}

// Override to enable webgl2 and support for high resolution and retina displays
p5.RendererGL.prototype._initContext = function() {
	try {
		// Attempt to get WebGL2 or experimental WebGL context
		this.drawingContext = this.canvas.getContext('webgl2', this._pInst._glAttributes) ||
			this.canvas.getContext('experimental-webgl', this._pInst._glAttributes);
		
		// Check if context creation failed
		if (this.drawingContext === null) {
			throw new Error('Error creating webgl context');
		} else {
			// Set up viewport dimensions for the WebGL context
			const gl = this.drawingContext; 
			gl.viewport(0, 0, ww, wh);
			this._viewport = this.drawingContext.getParameter(this.drawingContext.VIEWPORT);
		}
	} catch (er) {
		// Re-throw any errors that occur during context initialization
		throw er;
	}
};