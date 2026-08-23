function Resolve-ReleaseArtifactRepositoryDescendant {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryRoot,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [string]$Label = 'release artifact path'
  )

  $root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
    [char[]]@(
      [IO.Path]::DirectorySeparatorChar,
      [IO.Path]::AltDirectorySeparatorChar
    )
  )
  if ([string]::IsNullOrWhiteSpace($root)) {
    throw "$Label repository root is blank."
  }

  $candidate = if ([IO.Path]::IsPathRooted($Path)) {
    [IO.Path]::GetFullPath($Path)
  } else {
    [IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  $rootPrefix = $root + [IO.Path]::DirectorySeparatorChar
  if (-not $candidate.StartsWith(
      $rootPrefix,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    throw "$Label must stay inside the production repository."
  }

  return $candidate
}
