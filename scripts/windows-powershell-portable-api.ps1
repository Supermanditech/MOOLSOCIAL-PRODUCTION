function Get-MoolSocialPortableSha256Bytes {
  param([Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try { return ,($algorithm.ComputeHash($Bytes)) } finally { $algorithm.Dispose() }
}

function ConvertTo-MoolSocialPortableHex {
  param([Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes)
  return [BitConverter]::ToString($Bytes).Replace('-', '')
}

function Get-MoolSocialPortableRelativePath {
  param([Parameter(Mandatory)][string]$RelativeTo,[Parameter(Mandatory)][string]$Path)
  $basePath = [IO.Path]::GetFullPath($RelativeTo)
  $targetPath = [IO.Path]::GetFullPath($Path)
  $separator = [IO.Path]::DirectorySeparatorChar
  $trimChars = [char[]]@([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if ($basePath.TrimEnd($trimChars).Equals($targetPath.TrimEnd($trimChars),[StringComparison]::OrdinalIgnoreCase)) { return '.' }
  if (-not [IO.Path]::GetPathRoot($basePath).Equals([IO.Path]::GetPathRoot($targetPath),[StringComparison]::OrdinalIgnoreCase)) { return $targetPath }
  $baseUri = [Uri]::new($basePath.TrimEnd($trimChars) + $separator)
  $targetUri = [Uri]::new($targetPath)
  return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', $separator)
}
