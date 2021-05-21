# Bubble

此元件為Flex Message最基礎之核心元件。
![](https://developers.line.biz/assets/img/overviewSample.772a618f.png) <br/>
詳細說明請參考以下連結：<br/>
[LINE Flex Message 關於 Bubble 的說明文件](https://developers.line.biz/en/docs/messaging-api/flex-message-elements/#bubble) <br/>
[LINE Flex Message 關於 Bubble 的 API Reference](https://developers.line.biz/en/reference/messaging-api/#bubble)

## 使用範例




```
Kamiflex.build(self) do
    bubble do
        ...
    end
end
```



## 修改 size 的寫法

```
Kamiflex.build(self) do
    bubble size: :giga do
        ...
    end
end
```