/*
It is a 3D shader made for the weekly Creative Coding Challenge
(https://openprocessing.org/curation/78544) on the theme "Resistance".

The scene I depicted in this shader can be read as follows: Nothing
outside our biosphere is friendly to us; on the contrary, no living
thing can exist there. The bright, shining, perfect sphere at the
centre of the scene is trapped in the rugged rock, which in turn
exists in the endless, barren expanse of space-time. The earth is
the sphere. Our life is the sphere and the rock symbolises the
harshness of the world. Our life force stands up against the opposing
forces that surround us. Life means not giving up.

On a side note:
When I read the topic, I was reminded of "Every Man Dies Alone",
a 1947 novel by the German author Hans Fallada. It is based on the
true story of Otto and Elise Hampel.

https://en.wikipedia.org/wiki/Every_Man_Dies_Alone

*/

let theShader, dpr = Math.max(1, 0.5*window.devicePixelRatio), ww = window.innerWidth*dpr, wh = window.innerHeight*dpr;
const canvasStyle = 'width:100%;height:auto;touch-action:none;object-fit:contain;'

function windowResized() {
	ww = window.innerWidth*dpr; wh = window.innerHeight*dpr;
  resizeCanvas(ww, wh);
	const canvas = document.querySelector('canvas');
	canvas.style = canvasStyle;
}

function preload(){
	theShader = loadShader('vert.glsl', 'frag.glsl');
}

function setup() {
  pixelDensity(1);
  createCanvas(ww, wh, WEBGL);
	const canvas = document.querySelector('canvas');
	canvas.style = canvasStyle;
}

function draw() {
  shader(theShader);
  theShader.setUniform("resolution", [width, height]);
  theShader.setUniform("time", millis() / 1000.0);
  rect(0,0,width,height);
}

// Override to enable webgl2 and support for high resolution and retina displays
p5.RendererGL.prototype._initContext = function() {
	try { this.drawingContext = this.canvas.getContext('webgl2', this._pInst._glAttributes) ||
			this.canvas.getContext('experimental-webgl', this._pInst._glAttributes);
		if (this.drawingContext === null) { throw new Error('Error creating webgl context');
		} else { const gl = this.drawingContext; 
			gl.viewport(0, 0, ww, wh);
			this._viewport = this.drawingContext.getParameter(this.drawingContext.VIEWPORT);
		} } catch (er) { throw er; }
};