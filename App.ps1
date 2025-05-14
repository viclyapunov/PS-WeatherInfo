Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.Web

# Создаем главное окно
$form = New-Object System.Windows.Forms.Form
$form.Text = "Прогноз погоды"
$form.Width = 960
$form.Height = 600
$form.StartPosition = "CenterScreen"

# Словарь соответствий "Отображаемое имя" -> "Название для URL"
$cityMappings = @{
    "Москва" = "Moscow"
    "Домодедово" = "Domodedovo"
    "Кашира" = "Kashira"
    "Минеральные воды" = "Mineralnye+Vody"
    "Анталья" = "Antalya"
}

# GroupBox для верхних элементов (ComboBox и Button)
$topGroupBox = New-Object System.Windows.Forms.GroupBox
$topGroupBox.Text = "Выбор города"
$topGroupBox.Width = 920
$topGroupBox.Height = 80
$topGroupBox.Location = New-Object System.Drawing.Point(20, 10)
$form.Controls.Add($topGroupBox)

# Выпадающий список городов
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Width = 200
$comboBox.Height = 30
$comboBox.Location = New-Object System.Drawing.Point(20, 30)
$comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboBox.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 10)

# Добавляем города в список (только отображаемые имена)
$comboBox.Items.AddRange($cityMappings.Keys)
$comboBox.SelectedIndex = 0  # По умолчанию выбран первый город
$topGroupBox.Controls.Add($comboBox)

# Кнопка для получения погоды
$button = New-Object System.Windows.Forms.Button
$button.Text = "Получить погоду"
$button.Width = 150
$button.Height = 30
$button.Location = New-Object System.Drawing.Point(240, 30)
$topGroupBox.Controls.Add($button)

# GroupBox для RichTextBox
$outputGroupBox = New-Object System.Windows.Forms.GroupBox
$outputGroupBox.Text = "Прогноз погоды"
$outputGroupBox.Width = 920
$outputGroupBox.Height = 480
$outputGroupBox.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($outputGroupBox)

# RichTextBox для вывода погоды
$richTextBox = New-Object System.Windows.Forms.RichTextBox
$richTextBox.Multiline = $true
$richTextBox.ScrollBars = "Both"
$richTextBox.Width = 900
$richTextBox.Height = 450
$richTextBox.Location = New-Object System.Drawing.Point(10, 20)
$richTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$richTextBox.ReadOnly = $true
$outputGroupBox.Controls.Add($richTextBox)

# Обработчик нажатия кнопки
$button.Add_Click({
    try {
        $displayName = $comboBox.SelectedItem.ToString()
        $cityForUrl = $cityMappings[$displayName]
        
        # Отладочный вывод переменной $cityForUrl
        # [System.Windows.Forms.MessageBox]::Show("$cityForUrl", "cityForUrl")
                
        $richTextBox.Text = "Загружаю прогноз для $displayName..."
        $form.Refresh()

        # Настраиваем HttpClient
        $client = New-Object System.Net.Http.HttpClient
        $client.DefaultRequestHeaders.UserAgent.ParseAdd("curl")
        $client.DefaultRequestHeaders.Add("Accept-Language", "ru-RU")

        # Формируем URL (уже правильно закодирован в словаре)
        $url = "https://wttr.in/$cityForUrl"
        
        # Отладочный вывод итогового URL
        # [System.Windows.Forms.MessageBox]::Show("$url", "URL")
        
        # Запрашиваем данные
        $response = $client.GetAsync($url).Result

        if ($response.IsSuccessStatusCode) {
            $weatherData = $response.Content.ReadAsStringAsync().Result
            $cleanText = $weatherData -replace '\x1B\[[0-9;]*[mK]', ''
            $richTextBox.Text = $cleanText
        } else {
            $richTextBox.Text = "Ошибка: Сервер вернул код " + $response.StatusCode
        }
    } catch {
        $richTextBox.Text = "Ошибка: $_"
    }
})

# Показываем форму
$form.ShowDialog()