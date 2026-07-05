# Lua + LÖVE: hump.vector 徹底解説

`hump.vector`（または `vector-light`）は、LÖVE（Love2D）でのゲーム開発において、2次元座標の計算（位置、速度、加速度、衝突判定など）を直感的かつ高速に行うための定番ベクトルライブラリです。

本資料では、ライブラリの導入から基本操作、ゲーム開発で頻出する実践的なテクニックまでを網羅的に解説します。

---

## 1. 導入と基本構造

### ライブラリの読み込みとインスタンス化

ベクトルオブジェクトを生成するには、モジュールを読み込んだ後、`vector(x, y)` または省略形の `v(x, y)` を使用します。

```lua
local vector = require("hump.vector")

-- ベクトルの生成
local pos = vector(100, 150)
local vel = vector(5, -2)

-- 省略形としての登録（コードを短くしたい場合）
local v = vector
local player_pos = v(400, 300)

```

### プロパティのアクセス

生成されたベクトルオブジェクトは、`.x` および `.y` フィールドを持ち、直接数値を書き換えることも可能です。

```lua
local p = vector(10, 20)
print(p.x, p.y) -- 10, 20

p.x = 50        -- 値の直接変更が可能

```

---

## 2. 基本的な演算（演算子オーバーロード）

`hump.vector` は Lua のメタテーブルを利用して演算子がオーバーロードされているため、数学の式をそのままコードに落とし込めます。

### 四則演算と符号反転

ベクトル同士の加減算、およびスカラー（数値）との乗除算に対応しています。

```lua
local v1 = vector(10, 20)
local v2 = vector(5, 5)

-- ベクトル同士の加算・減算
local total = v1 + v2 -- vector(15, 25)
local diff  = v1 - v2 -- vector(5, 15)

-- スカラーとの乗算・除算（速度の倍加や調整）
local speed_up = v1 * 2   -- vector(20, 40)
local half     = v1 / 2   -- vector(5, 10)

-- 符号反転
local inverse = -v1       -- vector(-10, -20)

```

### 比較演算

2つのベクトルが完全に等しいかどうかを判定できます。

```lua
local a = vector(10, 20)
local b = vector(10, 20)

if a == b then
    -- 座標が完全に一致している場合の処理
end

```

---

## 3. 重要メソッド・関数リファレンス

ベクトル演算で頻出する主要なメソッドの一覧です。これらは `v:len()` のようにオブジェクトのメソッドとして呼び出します。

| メソッド / 関数 | 説明 | 主な用途 |
| --- | --- | --- |
| `v:len()` | ベクトルの長さ（絶対値）を返す。 | 移動速度の取得、距離の測定 |
| `v:len2()` | ベクトルの長さの平方（二乗）を返す。 | ルート計算を省く高速な距離比較 |
| `v:normalized()` | 向きを維持したまま、長さを1にしたベクトルを返す。 | 移動方向の純粋な抽出（単位ベクトル化） |
| `v:normalizeInplace()` | 自身のオブジェクト自体を単位ベクトルに書き換える。 | メモリ確保を抑えた最適化 |
| `v:dist(other)` | 2つのベクトル間の距離を返す。 | 衝突判定、敵との距離測定 |
| `v:dist2(other)` | 2つのベクトル間の距離の平方（二乗）を返す。 | 高速な近接判定 |
| `v:dot(other)` | 2つのベクトルの内積（スカラー）を返す。 | 視界判定（正面か背面か）、影の投影 |
| `v:permul(other)` | 要素ごとの乗算（Hadamard積）を行う。 | 軸ごとのスケール変更 |

---

## 4. ゲーム開発で使える実践テクニック集

### 4.1 斜め移動の減速を防ぐ（正規化）

キーボードで「右」と「上」を同時に押した際、単純に速度を加算すると移動速度が $\sqrt{2}$ 倍（約1.41倍）になってしまいます。これを防ぐために方向ベクトルを正規化します。

```lua
function love.update(dt)
    local dir = vector(0, 0)
    
    if love.keyboard.isDown("right") then dir.x = 1 end
    if love.keyboard.isDown("left")  then dir.x = -1 end
    if love.keyboard.isDown("down")  then dir.y = 1 end
    if love.keyboard.isDown("up")    then dir.y = -1 end

    -- 入力がある場合のみ正規化して移動
    if dir.x ~= 0 or dir.y ~= 0 then
        dir = dir:normalized()
        
        local speed = 200
        player.pos = player.pos + dir * speed * dt
    end
end

```

### 4.2 ターゲット（マウス・敵）へ向かう移動

プレイヤーからマウスカーソルの位置へ向かって弾を飛ばす、または敵を追従させる際の計算パターンです。

```lua
local player_pos = vector(400, 300)

function love.update(dt)
    local mouse_pos = vector(love.mouse.getPosition())
    
    -- ターゲットへの差分ベクトルを計算
    local to_target = mouse_pos - player_pos
    
    -- 距離が一定以上離れている場合のみ追従
    if to_target:len() > 5 then
        local direction = to_target:normalized()
        local speed = 150
        
        -- 移動処理
        player_pos = player_pos + direction * speed * dt
    end
end

```

### 4.3 高速な円形衝突判定（`dist2` による最適化）

`dist()` メソッドは内部で平方根（`math.sqrt`）を計算するため、大量のオブジェクトを判定すると処理が重くなります。二乗のまま比較する `dist2()` を使用することで計算負荷を下げられます。

```lua
local obj1 = { pos = vector(100, 100), radius = 20 }
local obj2 = { pos = vector(120, 110), radius = 15 }

local function check_circle_collision(a, b)
    -- 半径の合計の二乗
    local radius_sum = a.radius + b.radius
    local threshold = radius_sum * radius_sum
    
    -- 距離の二乗と比較（平方根の計算を回避）
    return a.pos:dist2(b.pos) < threshold
end

```

### 4.4 内積（Dot Product）を用いた視界判定

敵キャラクターの正面にプレイヤーがいるかどうか（視野角内に入っているか）を判定します。

```lua
-- enemy.dir: 敵の向きを表す単位ベクトル
-- enemy.pos: 敵の位置
-- player.pos: プレイヤーの位置

local to_player = (player.pos - enemy.pos):normalized()
local dot_product = enemy.dir:dot(to_player)

-- 内積値が 0.707 以上であれば、前方約90度の視界内に入っていると判定できる
if dot_product > 0.707 then
    -- プレイヤーを発見した時の処理
end

```

### 4.5 ベクトルの回転（向きの変更）

キャラクターの進行方向を基準に、左右に散弾を撃ち分けるようなケースでは `rotated()` メソッドが有効です。

```lua
local base_dir = vector(1, 0) -- 右向きのベクトル

-- ラジアン単位で回転（math.rad で度数からラジアンに変換）
local left_shot_dir  = base_dir:rotated(math.rad(-15))  -- 左に15度回転
local right_shot_dir = base_dir:rotated(math.rad(15))   -- 右に15度回転

```