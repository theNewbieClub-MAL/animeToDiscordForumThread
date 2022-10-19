#Requires -Version 7

[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

Function Find-MAL {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SearchQuery
  )

  $Encoded = [uri]::EscapeDataString($SearchQuery)
  $iwr = Invoke-WebRequest -Uri "https://api.jikan.moe/v4/anime?q=$($Encoded)&limit=20&sfw=false" -Method Get
  (ConvertFrom-Json ($iwr).content | Select-Object -Expand "data") | Select-Object mal_id,title,title_english | Format-Table

<#
    .SYNOPSIS
    Search for an anime on MyAnimeList.net

    .DESCRIPTION
    Search for an anime on MyAnimeList.net by utilizing 3rd Party MAL API by Jikan.moe.
    The search query is case-insensitive and can be a full title or a partial title.
    Title can be in English or Japanese.

    .EXAMPLE
    PS> Find-MAL "Naruto"

    mal_id title                                                                     title_english
    ------ -----                                                                     -------------
        20 Naruto                                                                    Naruto
     32365 Boruto: Naruto the Movie - Naruto ga Hokage ni Natta Hi                   Boruto: Naruto the Movie - The Day Naruto Became Hokage
     10686 Naruto: Honoo no Chuunin Shiken! Naruto vs. Konohamaru!!                  Naruto Shippuden: Chunin Exam on Fire! and Naruto vs. Konohamaru!
     10659 Naruto Soyokazeden Movie: Naruto to Mashin to Mitsu no Onegai Dattebayo!! Naruto: The Magic Genie and the Three Wishes
      1735 Naruto: Shippuuden                                                        Naruto Shippuden
     10075 Naruto x UT
     28755 Boruto: Naruto the Movie                                                  Boruto: Naruto the Movie
     16870 The Last: Naruto the Movie                                                The Last: Naruto the Movie
     34566 Boruto: Naruto Next Generations                                           Boruto: Naruto Next Generations
      7367 Naruto: The Cross Roads
     19511 Naruto: Shippuuden - Sunny Side Battle
     13667 Naruto: Shippuuden Movie 6 - Road to Ninja                                Road to Ninja: Naruto the Movie
      4134 Naruto: Shippuuden - Shippuu! "Konoha Gakuen" Den                         Naruto Shippuden: Konoha Gakuen - Special
      8246 Naruto: Shippuuden Movie 4 - The Lost Tower                               Naruto Shippuden the Movie: The Lost Tower
     36564 Kamiusagi Rope x Boruto: Naruto Next Generations
      2472 Naruto: Shippuuden Movie 1                                                Naruto: Shippuden the Movie
       936 Naruto Movie 2: Dai Gekitotsu! Maboroshi no Chiteiiseki Dattebayo!        Naruto the Movie 2: Legend of the Stone of Gelel
       442 Naruto Movie 1: Dai Katsugeki!! Yuki Hime Shinobu Houjou Dattebayo!       Naruto the Movie: Ninja Clash in the Land of Snow
      2144 Naruto Movie 3: Dai Koufun! Mikazuki Jima no Animaru Panikku Dattebayo!   Naruto the Movie 3: Guardians of the Crescent Moon Kingdom
      4437 Naruto: Shippuuden Movie 2 - Kizuna                                       Naruto: Shippuden the Movie 2 -Bonds-

    .LINK
    Get-MALTitle
  #>
}


Clear-Host

$search = Read-Host "Search"

Find-MAL $search

$malId = Read-Host "MAL ID"

Clear-Host

function Get-MALData {
  param(
    [Parameter(Mandatory = $true)]
    [string]$MALId
  )

  $iwr = Invoke-WebRequest -Uri "https://api.jikan.moe/v4/anime/$($MALId)" -Method Get
  $json = (ConvertFrom-Json ($iwr).content).data
  
  $date = $json.aired.prop.from
  $format = Get-Date "$($date.year)-$(($date.month).ToString('00'))-$(($date.day).ToString('00')) $($json.broadcast.time)"
  $tzH = ((Get-TimeZone).BaseUtcOffset.Hours) - 8
  $tzM = ((Get-TimeZone).BaseUtcOffset.Minutes) - 0
  $starts = (Get-Date ($format.AddHours($tzH).AddMinutes($tzM))).ToUniversalTime()
  $unix = Get-Date ($starts) -UFormat '%s'
  @"
# Forum Title: $($json.title)
  
$($json.synopsis)

**Japanese Title:** $($json.title_japanese)
**English Title:** $($json.title_english)
**Synonyms:** $($syn = @(); ForEach ($name in $json.title_synonyms) { $syn += $name }; $syn -Join "; ")

**Genres and Themes:** $(
$tags = @()
ForEach ($genre in $json.genres) { $tags += $genre.name }
ForEach ($theme in $json.themes) { $tags += $theme.name }
($tags | Sort-Object) -Join "; "
)

***Release date***: $(Get-Date $starts -Format "MMMM d, yyyy")

**Poster**: $($json.images.webp.large_image_url)
"@
}

Get-MALData -MALId $malId
