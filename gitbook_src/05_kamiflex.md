# 概觀
Kamiflex讓你以程式碼的方式取代Flex Messages JSON，達到方便、簡潔、易維護易擴展的目的。Kamiflex目前僅支援Line平台上的Flex Message，在Kamiflex之下Line Flex Message的架構如下：

![picture 1](/images/05_kamiflex-757eecf7ffa3d4023899750a3480ec2dd581db404920ac38ff194bf30f842afc.png)  

以kamigo預設的`index.line.erb`為例，其轉換為Json的關係圖如下：

<img src="https://i.imgur.com/VqGf3um.jpg" alt= "index.line.erb的Json關係圖" width= "400">

上圖數字代表意義為：
1. Flex Message Meta
2. 核心元件
3. 容器元件
4. 基礎組件

以Kamiflex編寫的程式碼會是以下：
```ruby
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
