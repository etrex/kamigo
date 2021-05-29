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
kamiflex會將該程式碼轉換為Json，`{...}`為block，可以在其中放入核心元件(如bubble、carousel)。

## 屬性
### alt_text
#### 說明
此屬性的修改放在Block中，預設文字為`this is a flex message`。
#### 使用範例
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
 


