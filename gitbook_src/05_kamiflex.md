# 概觀
Kamiflex讓你以程式碼的方式取代Flex Messages JSON，達到方便、簡潔、易維護易擴展的目的。Kamiflex目前僅支援Line平台上的Flex Message，Line Flex Message的架構如下：

```
├──Flex Message Header
    |
    ├──核心元件
        |
        ├──容器元件
            |
            ├──基礎組件
```

以kamigo的預設index.line.erb為例，其轉換為Json的關係圖如下：


<img src="https://i.imgur.com/VqGf3um.jpg" alt= "index.line.erb的Json關係圖" width= "400">

上圖數字代表意義為：
1. Flex Message Header
2. 核心元件
3. 容器元件
4. 基礎組件

以Kamiflex編寫的程式碼會是以下：
```
Kamiflex.build(self) do    #Flex Message Header
  bubble do                #核心元件
    body do                #核心元件屬性
      horizontal_box do    #容器元件
        text "🍔", flex: 0, action: message_action("/") #基礎組件
        text "Todos"       #基礎組件
        text "🆕", align: "end", action: uri_action(new_todo_path)#基礎組件
      end
      separator            #基礎組件
      if @todos.present?
        vertical_box margin: "lg" do                    #容器元件
          horizontal_box @todos, margin: "lg" do |todo| #容器元件
            text todo.name, action: message_action("/todos/#{todo.id}") #基礎組件
            text "❌", align: "end", action: message_action("DELETE /todos/#{todo.id}") #基礎組件
          end
        end
      else
        text "no contents yet", margin: "lg" #基礎組件
      end
    end
  end
end
```
在部分的元件後會加入一些屬性，達到修飾的效果。例如`text "no contents yet", margin: "lg"`，這是一個文字基礎元件，`text "no contents yet"`為主題，後方的`margin: "lg"`則用來修改該元件的屬性，部份元件的屬性修改則是放置於Block中，請依據文件規範編寫，若不額外指定則會使用預設的屬性。

關於屬性內容詳細說明請參照[flex message object](https://developers.line.biz/en/reference/messaging-api/#flex-message)
# Flex Message Header
Flex Message Header是每一個Flex Message一定會包含的部分，其Json為
```
 {
    type: "flex",
    altText: "this is a flex message",
    contents: {...}
}
```
對應的`Kamiflex`程式碼為
```
Kamiflex.build(self) {...}
```
kamiflex會將該程式碼轉換為Json，`{...}`為block，可以在其中放入核心元件(如bubble、carousel)。

### 屬性
- ### alt_text
    - 說明
        此屬性的修改放在Block中，預設文字為`this is a flex message`。
    - 使用範例
        ```
        Kamiflex.build(self) {
            alt_text("alt Text")
            ...
        }
        ```

# 核心元件
核心元件需被寫在Flex Message Header的block之中。
- ### bubble
    - 說明
        此元件為Flex Message最基礎之核心元件。
        ![](https://developers.line.biz/assets/img/overviewSample.772a618f.png) <br/>
        詳細說明請參考以下連結：<br/>
        [LINE Flex Message 關於 Bubble 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#bubble) <br/>
        [LINE Flex Message 關於 Bubble 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#bubble)
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                ...
            end
        end
        ```
        修改 size 的寫法：
        ```
        Kamiflex.build(self) do
            bubble size: :giga do
                ...
            end
        end
        ```

- ### bubbles
    - 說明
        此元件主要運用在`carousel`之中，達成橫向多筆Flex Message，若不使用此核心元件，亦可使用Ruby原生的`#each`搭配`bubble`達到相同功能。
    - 使用範例
        ```
        Kamiflex.build(self) do
            carousel do
                bubbles @vars do |var|
                    ...
                end
            end
        end
        ```
- ### carousel
    - 說明
        此元件可以達成橫向多筆的Flex Message，但在其之中還需要加上bubble元件。
    - 使用範例
        ```
        Kamiflex.build(self) do
            carousel do
                @vars.each do |var|
                    bubble do
                        ...
                    end
                end
            end
        end
        ```
### 屬性
核心元件屬性需放置在bubble或是bubbles的block之中，並且各個屬性應確保其Json同層而不存在上下層關聯。
- ### header
    - 說明
        呈現在Flex Message最頂部，一般用來放置標題使用
    - 參數
        - `layout`：預設`horizontal`
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                header layout: "vertical" do
                ...
                end
            end
        end
        ```
- ### hero
    - 說明
        呈現在Flex Message `header`之下，`body`之上，一般用來放置圖片，**由於不需要搭配block。後方不需再加入`{...}`或是`do...end`**。
    - 參數
        - `type`：預設`image`
        - `url`：搭配`type: "image"`使用，需填入圖片網址
        - 其餘style可查詢[image styles](https://developers.line.biz/en/reference/messaging-api/#f-image)
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                hero "https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png",
        size: :full, aspectRatio: "20:13"
            end
        end
        ```
    > hero也可以更改`type:"image"`為`type:"box"`，但這將與body用途重複，因此這邊就不進一步介紹

- ### body
    - 說明
        呈現在Flex Message中間的位置，一般用於表達內文。
    - 參數
        - `type`： 預設為`box`
        - `layout`： 預設為`vertical`
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                body do
                    ...
                end
            end
        end
        ```
- ### footer
    - 說明
        呈現在Flex Message最底部的位置，一般用於放置按鈕。
    - 參數
        - `type`： 預設為`box`
        - `layout`： 預設為`vertical`
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                footer do
                    ...
                end
            end
        end
        ```
- ### styles
    - 說明
        主要功能為更改核心元件屬性的style。
    - 參數
        只接受一個Hash。
    - 使用範例
        ```
        Kamiflex.build(self) do
            bubble do
                header {...}
                hero "https://image.jpg"
                body {...}
                footer {...}
                styles ({header: {
     		   "backgroundColor": "#00ffff"
     		 },
     		 hero: {
     		   "separator": true,
     		   "separatorColor": "#000000"
     		 },
                body: {
     		   "backgroundColor": "#00ffff"
     		 },
     		 footer: {
     		   "backgroundColor": "#00ffff",
     		   "separator": true,
     		   "separatorColor": "#000000"
     		 }})
            end
        end
        ```

# 容器元件
容器元件需被寫在核心元件或是核心元件屬性的block之中。
- ### box
    - horizontal_box
    - vertical_box
    - baseline_box
    - 說明
    - 使用範例
- ### icon
- ### separator
- ### spacer
- ### filler
# 基礎組件
基礎組件需被包含在容器元件中或是部分的已含有容器元件的核心元件屬性(如:header、body、footer)。
- ### text
    - 說明
    - 使用範例
- ### image
    - 說明
    - 使用範例
- ### button
    - message_button
    - postback_button
    - postback_text_button
    - 說明
    - 使用範例