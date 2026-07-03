# gemini response

Lua + LÖVE (Love2D) で背景を敷き詰めて表示（タイリング）し、さらにスクロールさせる方法には、**定番の外部ライブラリを使う方法**と、軽量な用途であれば**標準機能（または数行のコード）で自作する方法**の2通りがあります。

要件に合わせて選ぶのが一番ですが、まずは代表的なアプローチを紹介します。

---

## 1. 外部ライブラリを使う（本格的なマップ・背景用）

ゲーム用の本格的なマップエディタ「**Tiled Map Editor**」で背景を敷き詰め、それをLÖVEで読み込んでスクロールさせたい場合は、以下のライブラリがデファクトスタンダードです。

### STI (Simple Tiled Implementation)
LÖVEコミュニティで最も有名なライブラリです。Tiledで作成し、Lua形式でエクスポートしたマップデータを数行で読み込み・描画できます。

* **特徴**: レイヤー機能、自動スクロール（カメラ移動）、衝突判定（Bump.luaやBox2D）との連携が容易。
* **スクロールの実現**: `map:draw(tx, ty)` のように、引数にカメラの座標（`tx`, `ty`）を渡すだけで簡単にスクロール処理ができます。

---

## 2. LÖVEの標準機能で「無限スクロール背景」を作る（ライブラリ不要）

「1枚、あるいは数枚の背景画像を画面いっぱいに敷き詰めて、シューティングゲームやランゲームのようにループスクロール（リピート表示）させたい」という目的であれば、**ライブラリを使わずに標準機能だけで実装した方が圧倒的に軽快で簡単**です。

LÖVEの `love.graphics.newImage` で読み込んだ画像は、**`WrapMode`（折り返しモード）を `repeat` に設定する**ことで、テクスチャを無限に敷き詰めることができます。

### 実装サンプルコード
Quad（テクスチャの切り出し範囲）をカメラの移動に合わせてずらすことで、簡単に敷き詰め＆スクロール背景が作れます。

```lua
local bgImage
local bgQuad
local camX, camY = 0, 0
local scrollSpeed = 100 -- 秒間のスクロールピクセル数

function love.load()
    -- 1. 背景画像の読み込み
    bgImage = love.graphics.newImage("background.png") -- ループ可能な画像
    
    -- 2. 画像のラップモードをリピート（敷き詰め）に設定
    bgImage:setWrap("repeat", "repeat")
    
    -- 3. 画面サイズより遥かに大きい Quad を作成する
    -- ※ここでは例として 10000x10000 ピクセル分の敷き詰め範囲を確保
    bgQuad = love.graphics.newQuad(0, 0, 10000, 10000, bgImage:getDimensions())
end

function love.load()
    -- 1. 背景画像の読み込み
    bgImage = love.graphics.newImage("background.png")
    
    -- 2. 画像のラップモードをリピート（敷き詰め）に設定
    bgImage:setWrap("repeat", "repeat")
    
    -- 3. 画面サイズ（あるいはそれ以上）の Quad を作成
    local w, h = love.graphics.getDimensions()
    bgQuad = love.graphics.newQuad(0, 0, w, h, bgImage:getDimensions())
end

function love.update(dt)
    -- 時間経過でカメラの座標を動かす（右下にスクロール）
    camX = camX + scrollSpeed * dt
    camY = camY + scrollSpeed * dt
    
    -- Quadの表示開始位置を動かすことで、無限スクロールを表現
    -- （画像のサイズを超えたらループするように math.fmod を使うとより安全です）
    bgQuad:setViewport(camX, camY, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.draw()
    -- 敷き詰められた背景を描画（画面の左上 0, 0 から画面サイズ分描画される）
    love.graphics.draw(bgImage, bgQuad, 0, 0)
    
    -- デバッグ情報
    love.graphics.print("X: " .. math.floor(camX) .. " Y: " .. math.floor(camY), 10, 10)
end
```

---

## 3. カメラ管理ライブラリと組み合わせる（おすすめ）

もし背景だけでなく、プレイヤーや敵、オブジェクト全体をスクロール（カメラ移動）させたい場合は、シンプルなカメラライブラリを導入するのが一番スマートです。

* **gamera** や **hump.camera**
    * これらを使うと、`camera:attach()` と `camera:detach()` で挟むだけで、その中の描画要素がすべてカメラ座標基準（スクロール対応）になります。
    * 前述の「2次元配列（テーブル）による自作のタイル敷き詰め」の実装と組み合わせることで、最も自由度の高い2Dスクロールゲームの土台が作れます。

**結論として：**
ステージ単位のマップデータを敷き詰めたいなら **STI**、2Dゲームによくある「背景テクスチャをひたすらリピートして流したい」だけなら **`Image:setWrap("repeat")` を使った自作**が最適です。どちらの方向性がイメージに近いですか？

---

# gemini response

**hump.camera**（通称 `hump` ライブラリの一部）は、LÖVEでスクロール、ズーム、回転などを伴う「カメラ機能」を最も簡単に実装できる定番ライブラリの一つです。

基本的な考え方は**「カメラの視点（レンズ）を通して世界を見る」**というイメージです。カメラの内側（影響を受ける世界）と、外側（UIや固定背景など）を明確に分けて描画します。

---

## 1. 導入と基本セットアップ

まずは、`hump` のリポジトリなどから `camera.lua` をダウンロードし、プロジェクトに配置します。

### 基本構造のコード
以下が、`hump.camera` を使ってプレイヤーを画面の中心に追従（スクロール）させる最小構成のコードです。

```lua
-- ライブラリの読み込み
local Camera = require "camera"
local cam
local player = { x = 400, y = 300, speed = 200 }

function love.load()
    -- カメラオブジェクトの生成（初期位置をプレイヤーの初期位置にする）
    cam = Camera(player.x, player.y)
end

function love.update(dt)
    -- プレイヤーの移動処理（矢印キー）
    if love.keyboard.isDown("left")  then player.x = player.x - player.speed * dt end
    if love.keyboard.isDown("right") then player.x = player.x + player.speed * dt end
    if love.keyboard.isDown("up")    then player.y = player.y - player.speed * dt end
    if love.keyboard.isDown("down")  then player.y = player.y + player.speed * dt end

    -- 【超重要】カメラの位置をプレイヤーの座標にスムーズに追従させる
    -- smooth（滑らかさ）の値を小さくするとキビキビ動き、大きくするとじわっと追従します
    local dt_smooth = 10 * dt
    cam:lookAt(
        cam.x + (player.x - cam.x) * dt_smooth,
        cam.y + (player.y - cam.y) * dt_smooth
    )
end

function love.draw()
    -- ==================================================
    -- 1. カメラの影響を受ける世界（ゲーム世界）
    -- ==================================================
    cam:attach()

        -- ここに描画したものは、プレイヤーの動きに合わせてスクロールします
        -- 背景のグリッドやタイル、敵キャラなどをここに描く
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", player.x, player.y, 32, 32) -- プレイヤー
        
        -- 目印用の適当な障害物
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 200, 200, 100, 100)

    cam:detach()

    -- ==================================================
    -- 2. カメラの影響を受けない世界（画面に固定されるUIなど）
    -- ==================================================
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("プレイヤーの座標: " .. math.floor(player.x) .. ", " .. math.floor(player.y), 10, 10)
    love.graphics.print("カメラの座標: " .. math.floor(cam.x) .. ", " .. math.floor(cam.y), 10, 30)
end
```

---

## 2. よく使う主要な機能（API）

`hump.camera` には、スクロール演出を豊かにするための便利な関数が揃っています。

### ① ズーム（拡大・縮小）
画面全体の倍率を変更します。数字が大きいほどズームイン（拡大）、小さいほどズームアウト（縮小）します。デフォルトは `1` です。
```lua
-- 2倍にズームイン
cam:zoomTo(2)

-- マウスホイールなどで動的にズームを変更したい場合
cam:zoom(1.1) -- 現在のズーム倍率に 1.1 を乗算
```

### ② 回転（画面の傾き）
カメラを回転させることができます。ラジアン（`math.rad`）で指定します。
```lua
-- 画面を右に45度傾ける
cam:rotateTo(math.rad(45))
```

### ③ 座標変換（重要：クリック判定など）
「カメラで画面がスクロールしている状態」で画面をマウス白クリックした際、**画面上のマウス座標（UI上の座標）を、ゲーム世界の中の絶対座標に変換する**必要があります。これを行わないと、スクロールした先でオブジェクトを正しくクリックできません。

```lua
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- 画面上の (x, y) を、ゲーム世界の中の絶対座標 (worldX, worldY) に変換
        local worldX, worldY = cam:cameraCoords(x, y)
        
        print("ゲーム世界でのクリック位置:", worldX, worldY)
    end
end
```
> ※ 逆に、ゲーム世界のオブジェクトが「今画面のどの位置（ピクセル）に映っているか」を知りたい場合は `cam:worldCoords(wx, wy)` を使います。

---

## 3. 実践テクニック：画面揺れ（シェイク）

シューティングゲームやアクションゲームで攻撃が当たった時などの「画面揺れ」も、カメラ座標にノイズを足すだけで簡単に表現できます。

```lua
local shakeDuration = 0
local shakeMagnitude = 0

-- 揺れを発生させる関数
function startShake(duration, magnitude)
    shakeDuration = duration
    shakeMagnitude = magnitude
end

function love.update(dt)
    -- 通常の追従処理
    local targetX, targetY = player.x, player.y
    
    -- 画面揺れの計算
    if shakeDuration > 0 then
        shakeDuration = shakeDuration - dt
        -- ランダムに座標をずらす
        targetX = targetX + love.math.random(-shakeMagnitude, shakeMagnitude)
        targetY = targetY + love.math.random(-shakeMagnitude, shakeMagnitude)
    end
    
    cam:lookAt(targetX, targetY)
end
```

`cam:attach()` と `cam:detach()` のルールさえ守れば、座標計算のドロドロした部分をすべてライブラリが裏で処理してくれるため、格段に開発が楽になります！