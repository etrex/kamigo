# 容器元件
容器元件需被放置在 [header](/kamiflex/core.md#header)、[body](/kamiflex/core.md#body) 或 [footer](/kamiflex/core.md#footer) 的 `do ... end` 之中。 
## Horizontal Box
#### 說明
Kamiflex 會為 Horizontal Box 新增一個 box，並且將該 box 的 layout 引數設成 horizontal，關於 box 的說明請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.hash(self) do
  bubble do
    body do
      horizontal_box backgroundColor: "#f2f2f2",cornerRadius: "20px" do
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#ff0000",flex: 2
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#0000ff",flex: 2
      end
    end
  end
end
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "box",
          "layout": "horizontal",
          "contents": [
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#ff0000",
              "flex": 2
            },
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#0000ff",
              "flex": 2
            }
          ],
          "backgroundColor": "#f2f2f2",
          "cornerRadius": "20px"
        }
      ]
    }
  }
}
```

## Vertical Box
#### 說明
Kamiflex 會為 Vertical Box 新增一個 box，並且將該 box 的 layout 引數設成 vertical，關於 box 的說明請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)。

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      vertical_box backgroundColor: "#f2f2f2",cornerRadius: "20px" do
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#ff0000",flex: 2
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#0000ff",flex: 2
      end
    end
  end
end
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "box",
          "layout": "vertical",
          "contents": [
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#ff0000",
              "flex": 2
            },
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#0000ff",
              "flex": 2
            }
          ],
          "backgroundColor": "#f2f2f2",
          "cornerRadius": "20px"
        }
      ]
    }
  }
}
```

## Baseline Box
#### 說明
Kamiflex 會為 Baseline Box 新增一個 box，並且將該 box 的 layout 引數設成 baseline，關於 box 的說明請參考官方文件中的 [LINE Flex Message 關於 BOX 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#box)。

關於 baseline_box 與 horizontal_box 的差別，請查看官方文件中的 [Characteristics of a baseline box](https://developers.line.biz/en/docs/messaging-api/flex-message-layout/#baseline-box)

#### 可用的引數
[說明](/05_kamiflex.md#引數)

- layout
- backgroundColor
- borderColor
- borderWidth
- cornerRadius
- width
- height
- flex
- spacing
- margin
- paddingAll
- paddingTop
- paddingBottom
- paddingStart
- paddingEnd
- position
- offsetTop
- offsetBottom
- offsetStart
- offsetEnd
- [action](/kamiflex/action.md)
- justifyContent
- alignItems
- background.type
- background.angle
- background.startColor
- background.endColor
- background.centerColor
- background.centerPosition


#### 區塊中的方法
[說明](/05_kamiflex.md#區塊中的方法)

- [容器元件](/kamiflex/container.md)
- [基礎組件](/kamiflex/basic_element.md)

#### 使用範例
Ruby 寫法：
```ruby
Kamiflex.json(self) do
  bubble do
    body do
      baseline_box backgroundColor: "#f2f2f2",cornerRadius: "20px" do
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#ff0000",flex: 2
        text "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",wrap:true,color:"#0000ff",flex: 2
      end
    end
  end
end
```
對應的 JSON：
```json
{
  "type": "flex",
  "altText": "this is a flex message",
  "contents": {
    "type": "bubble",
    "body": {
      "type": "box",
      "layout": "vertical",
      "contents": [
        {
          "type": "box",
          "layout": "baseline",
          "contents": [
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#ff0000",
              "flex": 2
            },
            {
              "type": "text",
              "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
              "wrap": true,
              "color": "#0000ff",
              "flex": 2
            }
          ],
          "backgroundColor": "#f2f2f2",
          "cornerRadius": "20px"
        }
      ]
    }
  }
}
```