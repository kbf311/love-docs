# Lua + LÖVE シェーダー（Shader）実践テクニック集

LÖVE（Love2D）において、シェーダー（GLSL）はグラフィックスの表現力を飛躍的に向上させる強力なツールです。本書は、LÖVEでシェーダーを導入する基本構造から、そのままゲームに組み込める実践的なテクニックまでを網羅したマニュアルです。

---

## 1. LÖVEにおけるシェーダーの基本構造

LÖVEでは、GLSL（OpenGL Shading Language）を用いてシェーダーを記述します。主に二次元グラフィックスのピクセル色を計算するピクセルシェーダー（フラグメントシェーダー）が多用されます。

### 基本テンプレート

LÖVEの `love.graphics.newShader` に渡すコードでは、定義する関数名に固有のルールがあります。ピクセルシェーダーの基本関数名は `effect` です。

```lua
-- main.lua
local shader

function love.load()
    -- シェーダーコードの定義
    local shaderCode = [[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            // テクスチャの元のピクセル色を取得
            vec4 pixel = Texel(texture, texture_coords);
            -- 引数のcolor（love.graphics.setColorで設定された色）を乗算して返す
            return pixel * color;
        }
    ]]
    shader = love.graphics.newShader(shaderCode)
end

function love.draw()
    love.graphics.setShader(shader) -- シェーダーの適用開始
    -- ここに描画処理（画像や図形）
    love.graphics.draw(image, 100, 100)
    love.graphics.setShader()       -- シェーダーの適用解除
end

```

### 引数の仕様

* `vec4 color`: `love.graphics.setColor` で指定された色。
* `Image texture`: 描画対象のテクスチャ（画像）。
* `vec2 texture_coords`: テクスチャ内の座標（$0.0$ ～ $1.0$ に正規化されている）。
* `vec2 screen_coords`: 画面上の実際のピクセル座標（例: $800 \times 600$ の画面なら $x$ は $0$ ～ $800$）。

---

## 2. 実践テクニック集

### ① 画面のグレースケール（白黒）化

画面全体、または特定のオブジェクトをモノクロ化します。輝度計算には人間の目の特性に合わせたウェイト（NTSC系）を使用します。

#### シェーダーコード

```glsl
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    // 輝度の計算
    float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(vec3(gray), pixel.a) * color;
}

```

---

### ② 外部パラメータの制御（Uniform変数の利用）

Lua側から時間や数値をシェーダーに送り、動的な変化を作り出します。GLSL側で `uniform` キーワードを使用し、Lua側から `shader:send` で値を送ります。

#### 応用例：赤みがかった点滅（被ダメージ演出など）

```lua
-- main.lua
local shader
local timer = 0

function love.load()
    local code = [[
        uniform float flashIntensity; // Luaから制御する変数
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);
            // 赤色成分を強める
            pixel.r = mix(pixel.r, 1.0, flashIntensity);
            return pixel * color;
        }
    ]]
    shader = love.graphics.newShader(code)
end

function love.update(dt)
    timer = timer + dt
    -- サイン波を使って0.0〜0.5の間で滑らかに変化させる
    local intensity = (math.sin(timer * 10) + 1) / 4
    shader:send("flashIntensity", intensity)
end

```

---

### ③ CRTモニター風走査線エフェクト

レトロゲームの雰囲気を再現するため、画面に等間隔の横線（走査線）とわずかな湾曲、色収差を加えるテクニックです。画面全体を対象とするため、キャンバス（`love.graphics.newCanvas`）に対して適用するのが効果的です。

#### シェーダーコード

```glsl
uniform float time;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // 走査線の計算（画面座標のY軸を基準にする）
    float scanline = sin(screen_coords.y * 1.5 + time * 5.0) * 0.1 + 0.9;
    
    // RGBずらし（色収差）
    vec2 shift = vec2(0.002, 0.0);
    vec4 r_col = Texel(texture, texture_coords + shift);
    vec4 g_col = Texel(texture, texture_coords);
    vec4 b_col = Texel(texture, texture_coords - shift);
    
    vec4 pixel = vec4(r_col.r, g_col.g, b_col.b, g_col.a);
    return pixel * scanline * color;
}

```

---

### ④ 2Dメタボール（流体・ドロドロした表現）

複数の円が近づいたときに、磁石のように吸い付いて1つの流体のようにつながる表現です。このテクニックでは、オブジェクトの位置配列をシェーダーに転送します。

#### Lua側実装

```lua
local shader
local balls = {
    {x = 200, y = 300, r = 40},
    {x = 400, y = 300, r = 60},
    {x = 500, y = 350, r = 50}
}

function love.load()
    local code = [[
        uniform vec3 numBalls[3]; // x, y, radius を格納する配列
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            float density = 0.0;
            for (int i = 0; i < 3; i++) {
                vec2 center = numBalls[i].xy;
                float radius = numBalls[i].z;
                float dist = distance(screen_coords, center);
                if (dist > 0.0) {
                    // 距離の逆二乗を足し合わせる
                    density += (radius * radius) / (dist * dist);
                }
            }
            
            // 閾値を超えた部分だけを塗りつぶす（滑らかなエッジを出す場合はsmoothstepを使用）
            if (density > 1.0) {
                return vec4(0.2, 0.8, 0.4, 1.0); // メタボールの色
            }
            return vec4(0.0); // 背景は透明
        }
    ]]
    shader = love.graphics.newShader(code)
end

function love.update(dt)
    -- 例として1つのボールをマウスに追従させる
    balls[1].x = love.mouse.getX()
    balls[1].y = love.mouse.getY()
    
    -- シェーダーへ配列データを送信
    shader:send("numBalls", 
        {balls[1].x, balls[1].y, balls[1].r},
        {balls[2].x, balls[2].y, balls[2].r},
        {balls[3].x, balls[3].y, balls[3].r}
    )
end

function love.draw()
    love.graphics.setShader(shader)
    -- シェーダーを画面全体に適用するため、画面サイズの矩形を描画
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setShader()
end

```

---

## 3. パフォーマンスと運用の注意点

1. **Canvas（テクスチャ）のバインド回数を最小限にする**
シェーダーの切り替え（`love.graphics.setShader`）やCanvasの切り替えは描画処理において高コストです。同じシェーダーを使用する描画は、できる限りまとめてバッチ処理を行ってください。
2. **GLSL内での分岐（if文）を避ける**
GPUは並列処理を得意としますが、ピクセルごとに条件分岐（`if-else`）が発生すると処理効率が著しく低下します。極力 `step`, `smoothstep`, `clamp`, `mix` などのビルトイン関数を利用して数式的に解決してください。
3. **変数の型を厳密に書く**
GLSLは型に非常に厳格です。浮動小数点数（`float`）を扱う際は、必ず `0` ではなく `0.0` と記述してください（`float speed = 1;` はコンパイルエラーの原因になります）。