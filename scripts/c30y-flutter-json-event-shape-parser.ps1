Set-StrictMode -Version Latest

function ConvertTo-C30YFlutterJsonLineClassification {
  param([AllowNull()][object]$RawLine)

  $text = [string]$RawLine
  if ([string]::IsNullOrWhiteSpace($text)) {
    return [pscustomobject]@{ Kind = 'blank'; Event = $null }
  }
  try {
    $event = $text | ConvertFrom-Json
  } catch {
    return [pscustomobject]@{ Kind = 'non_json'; Event = $null }
  }
  if ($null -eq $event) {
    return [pscustomobject]@{ Kind = 'json_null'; Event = $null }
  }
  return [pscustomobject]@{ Kind = 'object'; Event = $event }
}

function Get-C30YFlutterJsonEventType {
  param([Parameter(Mandatory)][object]$Event)

  $property = $Event.PSObject.Properties['type']
  if ($null -eq $property) {
    return $null
  }
  $value = [string]$property.Value
  if ([string]::IsNullOrWhiteSpace($value)) {
    return $null
  }
  return $value
}

function Get-C30YFlutterJsonEventPropertyNames {
  param(
    [Parameter(Mandatory)][object]$Event,
    [int]$MaximumNames = 20,
    [int]$MaximumNameLength = 64
  )

  $names = @(
    $Event.PSObject.Properties |
      Select-Object -First $MaximumNames |
      ForEach-Object {
        $name = [string]$_.Name
        $safe = [regex]::Replace($name, '[^A-Za-z0-9_.-]', '_')
        if ($safe.Length -gt $MaximumNameLength) {
          $safe = $safe.Substring(0, $MaximumNameLength)
        }
        $safe
      }
  )
  if ($names.Count -eq 0) {
    return '(none)'
  }
  return ($names -join ',')
}
