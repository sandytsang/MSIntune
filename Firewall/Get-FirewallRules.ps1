# Get currently active network profiles
$activeProfiles = (Get-NetConnectionProfile).NetworkCategory
$activeProfiles = $activeProfiles | ForEach-Object {
    switch ($_) {
        'DomainAuthenticated' { 'Domain' }
        'Domain'              { 'Domain' }
        'Private'             { 'Private' }
        'Public'              { 'Public' }
        default               { $_ }
    }
}

# Get all enabled firewall rules from ActiveStore (runtime)
$rules = Get-NetFirewallRule -PolicyStore ActiveStore | Where-Object { $_.Enabled -eq $true }

$report = foreach ($rule in $rules) {
    # Use ToString() for Profile to handle enum type
    $profileText = $rule.Profile.ToString()

    # Convert to array of normalized profile names
    if ($profileText -eq 'Any') {
        $ruleProfiles = @('Domain','Private','Public')
    } else {
        $ruleProfiles = ($profileText -split ',\s*' | ForEach-Object {
            switch ($_) {
                'DomainAuthenticated' { 'Domain' }
                'Domain'              { 'Domain' }
                'Private'             { 'Private' }
                'Public'              { 'Public' }
                default               { $_ }
            }
        })
    }

    # Determine which active profiles enforce this rule
    $enforcedProfiles = $activeProfiles | Where-Object { $_ -in $ruleProfiles }

    [PSCustomObject]@{
        DisplayName       = $rule.DisplayName
        Name              = $rule.Name
        Enabled           = $rule.Enabled
        Direction         = $rule.Direction
        Action            = $rule.Action
        RuleProfiles      = ($ruleProfiles -join ', ')
        ActiveProfiles    = ($activeProfiles -join ', ')
        EnforcedFor       = if ($enforcedProfiles) { $enforcedProfiles -join ', ' } else { 'None' }
        PrimaryStatus     = $rule.PrimaryStatus
        EnforcementStatus = ($rule.EnforcementStatus -join ', ')
        PolicyStoreSource = $rule.PolicyStoreSource
    }
}

# Show results
$report | Out-GridView
