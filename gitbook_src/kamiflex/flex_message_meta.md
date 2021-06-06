# Flex Message Meta
Flex Message Meta是每一個Flex Message一定會包含的部分，其Json為
```json
 {
    type: "flex",
    altText: "this is a flex message",
    contents: {...}
}
```
對應的`Kamiflex`程式碼為
```ruby
Kamiflex.build(self) do
    ...
end
```
Kamiflex 會將該程式碼轉換為JSON，`do...end`為block，可以在其中放入 [核心元件](/kamiflex/core.md)。
## Class Method
下列為 Kamiflex 可以使用的 Class Method，如 `Kamiflex.json`

- .hash
- .to_hash
- .build
- .json
- .compact_json

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- parent (必填)

#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- alt_text

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.build(self) do
    alt_text "test alt text"
    bubble do
      body do
        text "Hello, World!"
      end
    end
end
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "test alt text",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "text",
          "text": "Hello, World!"
        }
      ]
    }
  }
}

```
#### 運行結果
![picture 2](/images/flex_Message_meta-856a06e4a473cc80f7d9bf83ed2107c349830e0f43f4e7a80a1bde98af297b9d.jpeg)



