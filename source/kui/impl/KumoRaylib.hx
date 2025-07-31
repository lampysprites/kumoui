package kui.impl;

import raylib.Types;
import cpp.NativeArray;
import raylib.Raylib.*;
import raylib.Types.*;
import kui.KeyboardInput;
import kui.impl.Base;
import kui.FontType;
import kui.KumoUI;

class KumoRaylib extends Base {

    public var fontBold: Font;
    public var fontRegular: Font;
    public var shader: Shader;
    public var scale: Float;

    /**
     * 
     * precision mediump float;

uniform sampler2D u_texture;
uniform vec4 u_color;
uniform float u_buffer;
uniform float u_gamma;

varying vec2 v_texcoord;

void main() {
    float dist = texture2D(u_texture, v_texcoord).r;
    float alpha = smoothstep(u_buffer - u_gamma, u_buffer + u_gamma, dist);
    gl_FragColor = vec4(u_color.rgb, alpha * u_color.a);
}
     */
    public var src_fs = '
#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main()
{
    // float dist = texture2D(texture0, fragTexCoord).a;
    // float alpha = smoothstep(u_buffer - u_gamma, u_buffer + u_gamma, dist);
    // finalColor = vec4(fragColor.rgb, alpha * fragColor.a);

    float distOut = texture2D(texture0, fragTexCoord).a - 0.325;
    float deltaDistFrag = length(vec2(dFdx(distOut), dFdy(distOut)));
    float alpha = smoothstep(-deltaDistFrag, deltaDistFrag, distOut);

    finalColor = vec4(fragColor.rgb, alpha * fragColor.a);
}   
    ';

    public var keyMap: Map<Int, Key> = [
        // Letters
        KeyboardKey.KEY_A => Key.KEY_A,
        KeyboardKey.KEY_B => Key.KEY_B,
        KeyboardKey.KEY_C => Key.KEY_C,
        KeyboardKey.KEY_D => Key.KEY_D,
        KeyboardKey.KEY_E => Key.KEY_E,
        KeyboardKey.KEY_F => Key.KEY_F,
        KeyboardKey.KEY_G => Key.KEY_G,
        KeyboardKey.KEY_H => Key.KEY_H,
        KeyboardKey.KEY_I => Key.KEY_I,
        KeyboardKey.KEY_J => Key.KEY_J,
        KeyboardKey.KEY_K => Key.KEY_K,
        KeyboardKey.KEY_L => Key.KEY_L,
        KeyboardKey.KEY_M => Key.KEY_M,
        KeyboardKey.KEY_N => Key.KEY_N,
        KeyboardKey.KEY_O => Key.KEY_O,
        KeyboardKey.KEY_P => Key.KEY_P,
        KeyboardKey.KEY_Q => Key.KEY_Q,
        KeyboardKey.KEY_R => Key.KEY_R,
        KeyboardKey.KEY_S => Key.KEY_S,
        KeyboardKey.KEY_T => Key.KEY_T,
        KeyboardKey.KEY_U => Key.KEY_U,
        KeyboardKey.KEY_V => Key.KEY_V,
        KeyboardKey.KEY_W => Key.KEY_W,
        KeyboardKey.KEY_X => Key.KEY_X,
        KeyboardKey.KEY_Y => Key.KEY_Y,
        KeyboardKey.KEY_Z => Key.KEY_Z,

        // Numbers
        KeyboardKey.KEY_ZERO => Key.KEY_0,
        KeyboardKey.KEY_ONE => Key.KEY_1,
        KeyboardKey.KEY_TWO => Key.KEY_2,
        KeyboardKey.KEY_THREE => Key.KEY_3,
        KeyboardKey.KEY_FOUR => Key.KEY_4,
        KeyboardKey.KEY_FIVE => Key.KEY_5,
        KeyboardKey.KEY_SIX => Key.KEY_6,
        KeyboardKey.KEY_SEVEN => Key.KEY_7,
        KeyboardKey.KEY_EIGHT => Key.KEY_8,
        KeyboardKey.KEY_NINE => Key.KEY_9,

        // Symbols
        KeyboardKey.KEY_MINUS => Key.KEY_MINUS,
        KeyboardKey.KEY_EQUAL => Key.KEY_EQUALS,
        KeyboardKey.KEY_LEFT_BRACKET => Key.KEY_OPEN_BRACKET,
        KeyboardKey.KEY_RIGHT_BRACKET => Key.KEY_CLOSE_BRACKET,
        KeyboardKey.KEY_BACKSLASH => Key.KEY_BACKSLASH,
        KeyboardKey.KEY_SEMICOLON => Key.KEY_SEMICOLON,
        KeyboardKey.KEY_APOSTROPHE => Key.KEY_SINGLE_QUOTE,
        KeyboardKey.KEY_GRAVE => Key.KEY_GRAVE,
        KeyboardKey.KEY_COMMA => Key.KEY_COMMA,
        KeyboardKey.KEY_PERIOD => Key.KEY_PERIOD,
        KeyboardKey.KEY_SLASH => Key.KEY_SLASH,

        // Special keys
        KeyboardKey.KEY_ESCAPE => Key.KEY_ESCAPE,
        KeyboardKey.KEY_SPACE => Key.KEY_SPACE,
        KeyboardKey.KEY_ENTER => Key.KEY_ENTER,
        KeyboardKey.KEY_TAB => Key.KEY_TAB,
        KeyboardKey.KEY_BACKSPACE => Key.KEY_BACKSPACE,
        KeyboardKey.KEY_LEFT => Key.KEY_LEFT,
        KeyboardKey.KEY_RIGHT => Key.KEY_RIGHT,
        KeyboardKey.KEY_UP => Key.KEY_UP,
        KeyboardKey.KEY_DOWN => Key.KEY_DOWN,
        KeyboardKey.KEY_END => Key.KEY_END,
        KeyboardKey.KEY_HOME => Key.KEY_HOME,
        KeyboardKey.KEY_RIGHT_CONTROL => Key.KEY_CTRL,
        KeyboardKey.KEY_LEFT_CONTROL => Key.KEY_CTRL
    ];

    public function new(fontRegular: Font, fontBold: Font, usingSdf: Bool, debugDraw: Bool = false, scale: Float = 1.0) {
        super();

        this.fontBold = fontBold;
        this.fontRegular = fontRegular;
        this.scale = scale;
        shader = LoadShaderFromMemory(null, src_fs);

        KumoUI.init(this, debugDraw);
    }

    // NOTE: This code WILL break at some point, either if haxe, hxcpp or raylib-hx changes, this is GOD AWFUL code.
    public static function loadFontSDF(path: String): Font {
        var fontBytes = sys.io.File.getBytes(path);
        
        // NOTE: this is the hackiest code i've ever written, PERIOD.
        // This was needed because I just want to create an empty font, but the API doesn't allow it
        // Thus we use the underlying bits of raylib-hx to create a font with the data we want
        // But loadFontData returns a pointer to the data, and RLGlyphInfo is not one, using cpp.Star<RlGlyphInfo> instead causes it to try and get the pointer to the pointer, which is not what we want
        // So we use this BIG HACK to make sure the haxe compiler can't do anything with this code.
        var fontData = LoadFontData(fontBytes, fontBytes.length, 64,  untyped __cpp__("0"), 0, raylib.Types.FontType.FONT_SDF);

        // Again, we cannot init an empty font, so we have to create it with the data we want
        var font: FontImpl = untyped __cpp__("{ 0 }");
        font.baseSize = 64;
        font.glyphCount = 95;
        font.glyphs = fontData;

        // Create the atlas, make a Rectangle ** and stuff
        var atlas: Image = GenImageFontAtlas(font.glyphs, untyped __cpp__("&{0}", font.recs), 95, 64, 4, 1);

        // Set the texture to the font
        font.texture = LoadTextureFromImage(atlas);
        SetTextureFilter(font.texture, TextureFilter.TEXTURE_FILTER_BILINEAR);
        //raylib.genTextureMipmaps(font.texture);

        // Finally, unload the image
        UnloadImage(atlas);

        // Done with this mess!
        return font;
    }

    // Input
    override public function getMouseX(): Float return GetMouseX() / scale;
    override public function getMouseY(): Float return GetMouseY() / scale;
    override public function getLeftMouseDown(): Bool return IsMouseButtonDown(MouseButton.MOUSE_BUTTON_LEFT);
    override public function getRightMouseDown(): Bool return IsMouseButtonDown(MouseButton.MOUSE_BUTTON_RIGHT);
    override public function getScrollDelta():Float return GetMouseWheelMove() * 50;

    // Drawing Internals
    override public function beginDraw(): Void {}
    override public function endDraw(): Void {}
    override public function getDeltaTime(): Float return GetFrameTime();

    // Utils
    inline public function getRoundingPixels(surfaceWidth: Float, surfaceHeight: Float, rounding: Float) {
        var minAxis = Math.min(surfaceWidth, surfaceHeight);
        var roundness = rounding / (minAxis / 2);
        return roundness;
    }

    inline public function getColorFromInt(color: Int) {
        if (color > 0xFFFFFF) return new Color(
            (color >> 16) & 0xFF,
            (color >> 8) & 0xFF,
            color & 0xFF,
            (color >> 24) & 0xFF
        ) else return new Color(
            (color >> 16) & 0xFF,
            (color >> 8) & 0xFF,
            color & 0xFF,
            255
        );
    }

    inline public function rotatePoint(px:Float, py:Float, cx:Float, cy:Float, cosTheta:Float, sinTheta:Float):Vector2 {
        var dx = px - cx;
        var dy = py - cy;
        var newX = cx + dx * cosTheta - dy * sinTheta;
        var newY = cy + dx * sinTheta + dy * cosTheta;
        return new Vector2(newX, newY);
    }

    inline public function signedArea(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Float {
        return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3);
    }

    // Drawing
    override public function drawRect(x: Float, y: Float, width: Float, height: Float, color: Int, roundness: Float = 0): Void {
        var scaledX = x * scale;
        var scaledY = y * scale;
        var scaledWidth = width * scale;
        var scaledHeight = height * scale;
        var scaledRoundness = roundness * scale;
        
        if (scaledRoundness > 0) DrawRectangleRounded(new Rectangle(scaledX, scaledY, scaledWidth, scaledHeight), getRoundingPixels(scaledWidth, scaledHeight, scaledRoundness), 15, getColorFromInt(color));
        else DrawRectangle(Std.int(scaledX), Std.int(scaledY), Std.int(scaledWidth), Std.int(scaledHeight), getColorFromInt(color));
    }

    override function drawRectOutline(x:Float, y:Float, width:Float, height:Float, color:Int, thickness:Float = 1, roundness:Float = 0) {
        var scaledX = x * scale;
        var scaledY = y * scale;
        var scaledWidth = width * scale;
        var scaledHeight = height * scale;
        var scaledThickness = thickness * scale;
        var scaledRoundness = roundness * scale;
        
        // NOTE: drawRectangleLines doesn't have thickness, wat?
        // DrawRectangleRoundedLines(new Rectangle(x, y, width, height), getRoundingPixels(width, height, roundness), 15, Std.int(thickness), getColorFromInt(color));
        DrawRectangleRoundedLinesEx(new Rectangle(scaledX, scaledY, scaledWidth, scaledHeight), getRoundingPixels(scaledWidth, scaledHeight, scaledRoundness), 15, Std.int(scaledThickness), getColorFromInt(color));
    }

    override public function drawText(text: String, x: Float, y: Float, color: Int, size: Int = 16, font: FontType = FontType.REGULAR): Void {
        var scaledX = x * scale;
        var scaledY = y * scale;
        var scaledSize = Std.int(size * scale);
        
        BeginShaderMode(shader);
        DrawTextEx(font == FontType.REGULAR ? fontRegular : fontBold, text, new Vector2(Std.int(scaledX), Std.int(scaledY)), scaledSize, 0, getColorFromInt(color));
        EndShaderMode();
    }

    override public function measureTextWidth(text: String, size: Int = 16, font: FontType = FontType.REGULAR): Float {
        var scaledSize = Std.int(size * scale);
        var res = MeasureTextEx(font == FontType.REGULAR ? fontRegular : fontBold, text, scaledSize, 0);
        return res.x; // NOTE: doing this inline doesn't work?
    }

    override public function drawLine(x1: Float, y1: Float, x2: Float, y2: Float, color: Int, thickness: Float = 1): Void {
        var scaledX1 = x1 * scale;
        var scaledY1 = y1 * scale;
        var scaledX2 = x2 * scale;
        var scaledY2 = y2 * scale;
        var scaledThickness = thickness * scale;
        
        DrawLineEx(new Vector2(scaledX1, scaledY1), new Vector2(scaledX2, scaledY2), scaledThickness, getColorFromInt(color));
    }

    override public function setClipRect(x: Float, y: Float, width: Float, height: Float): Void {
        var scaledX = x * scale;
        var scaledY = y * scale;
        var scaledWidth = width * scale;
        var scaledHeight = height * scale;
        
        BeginScissorMode(Std.int(scaledX), Std.int(scaledY), Std.int(scaledWidth), Std.int(scaledHeight));
    }

    override function drawTriangle(cx:Float, cy:Float, len: Float, rotation:Float, color:Int) {
        var scaledCx = cx * scale;
        var scaledCy = cy * scale;
        var scaledLen = len * scale;
        
        var height = Math.sqrt(3) / 2 * scaledLen;

        var x1 = scaledCx - scaledLen / 2;
        var y1 = scaledCy + height / 3;
        var x2 = scaledCx + scaledLen / 2;
        var y2 = scaledCy + height / 3;
        var x3 = scaledCx;
        var y3 = scaledCy - 2 * height / 3;

        var cosTheta = Math.cos(rotation);
        var sinTheta = Math.sin(rotation);

        var p1 = rotatePoint(x1, y1, scaledCx, scaledCy, cosTheta, sinTheta);
        var p2 = rotatePoint(x2, y2, scaledCx, scaledCy, cosTheta, sinTheta);
        var p3 = rotatePoint(x3, y3, scaledCx, scaledCy, cosTheta, sinTheta);

        DrawTriangle(p1, p2, p3, getColorFromInt(color));
    }

    override function drawTrianglePoints(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, color:Int) {
        var scaledX1 = x1 * scale;
        var scaledY1 = y1 * scale;
        var scaledX2 = x2 * scale;
        var scaledY2 = y2 * scale;
        var scaledX3 = x3 * scale;
        var scaledY3 = y3 * scale;
        
        // NOTE: Raylib requires the points to be in counter-clockwise order, so we check the signed area to determine the order of the input and then draw the points in the correct order (CCW)
        if (signedArea(scaledX1, scaledY1, scaledX2, scaledY2, scaledX3, scaledY3) < 0) DrawTriangle(new Vector2(scaledX1, scaledY1), new Vector2(scaledX2, scaledY2), new Vector2(scaledX3, scaledY3), getColorFromInt(color));
        else DrawTriangle(new Vector2(scaledX1, scaledY1), new Vector2(scaledX3, scaledY3), new Vector2(scaledX2, scaledY2), getColorFromInt(color));
    }

    override public function drawCircle(cx: Float, cy: Float, radius: Float, color: Int): Void {
        var scaledCx = cx * scale;
        var scaledCy = cy * scale;
        var scaledRadius = radius * scale;
        
        DrawCircle(Std.int(scaledCx), Std.int(scaledCy), scaledRadius, getColorFromInt(color));
    }

    override public function resetClipRect(): Void {
        EndScissorMode();
    }

    override public function setClipboard(text: String): Void {
        SetClipboardText(text);
    }

    override public function getClipboard(): String {
        return GetClipboardText();
    }

    // Begin-end
    public function begin() {
        KumoUI.begin(Std.int(GetScreenWidth() / scale), Std.int(GetScreenHeight() / scale));
        KeyboardInput.setCurrentShiftMod(IsKeyDown(KeyboardKey.KEY_LEFT_SHIFT) || IsKeyDown(KeyboardKey.KEY_RIGHT_SHIFT));
        KeyboardInput.setCurrentCapsMod(IsKeyDown(KeyboardKey.KEY_CAPS_LOCK));

        // NOTE: getCharPressed would be ideal, but it makes it really annoying to work with.
        for (key in keyMap.keys()) {
            if (IsKeyDown(key)) KeyboardInput.reportKey(keyMap.get(key));
        }

        KeyboardInput.submit();
    }

    public function end() {
        KumoUI.render();
    }

}