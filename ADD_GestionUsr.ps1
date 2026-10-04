# Cargar modulo de Active Directory
Import-Module ActiveDirectory

# Funciones de logica
function Obtener-ResumenDominio {
    Clear-Host
    Write-Host ">>> RESUMEN GENERAL DEL DOMINIO <<<" -ForegroundColor Cyan
    Write-Host "----------------------------------" -ForegroundColor DarkGray
    
    $dominio = Get-ADDomain
    
    Write-Host "Host local:         $env:COMPUTERNAME"
    Write-Host "Dominio ActiveDir:  $($dominio.DNSRoot)"
    Write-Host "----------------------------------" -ForegroundColor DarkGray
    Write-Host "Unidades Org. (OU): $((Get-ADOrganizationalUnit -Filter *).Count)"
    Write-Host "Grupos totales:     $((Get-ADGroup -Filter *).Count)"
    Write-Host "Usuarios totales:   $((Get-ADUser -Filter *).Count)"
    
    Write-Host "`nPulse [ENTER] para regresar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

function Nueva-UnidadOrganizativa {
    Clear-Host
    Write-Host ">>> REGISTRAR NUEVA OU <<<" -ForegroundColor Cyan
    
    $nombre = Read-Host "Nombre de la OU"
    $padre = Read-Host "Ruta DN contenedor (ej: DC=miEmpresa,DC=local)"
    
    # Si no especifica ruta, toma el DN raiz
    if ([string]::IsNullOrWhiteSpace($padre)) {
        $padre = (Get-ADDomain).DistinguishedName
    }

    try {
        New-ADOrganizationalUnit -Name $nombre -Path $padre
        Write-Host "`n++ OU '$nombre' creada correctamente en$padre ++" -ForegroundColor Green
    }
    catch {
        Write-Host "`n-- Error al registrar la OU: $_ --" -ForegroundColor Red
    }

    Write-Host "`nPulse [ENTER] para regresar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

function Nuevo-GrupoSeguridad {
    Clear-Host
    Write-Host ">>> REGISTRAR NUEVO GRUPO <<<" -ForegroundColor Cyan
    
    $nombreGrupo = Read-Host "Nombre del grupo"
    $ubicacionDN = Read-Host "Ruta DN de la OU (ej: OU=Ventas,DC=miEmpresa,DC=local)"

    try {
        New-ADGroup -Name $nombreGrupo -Path$ubicacionDN -GroupScope Global -GroupCategory Security
        Write-Host "`n++ Grupo '$nombreGrupo' registrado con exito ++" -ForegroundColor Green
    }
    catch {
        Write-Host "`n-- Error al registrar el grupo: $_ --" -ForegroundColor Red
    }

    Write-Host "`nPulse [ENTER] para regresar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

function Nuevo-UsuarioAD {
    Clear-Host
    Write-Host ">>> REGISTRAR NUEVO USUARIO <<<" -ForegroundColor Cyan
    
    $nombre = Read-Host "Nombre"
    $apellidos = Read-Host "Apellidos"
    $login = Read-Host "Username (sAMAccountName)"
    $ouDestino = Read-Host "Ruta DN de la OU destino"
    $grupoAsignado = Read-Host "Grupo al que pertenecera"
    $claveSecreta = Read-Host "Contrasena temporal" -AsSecureString

    $dominioActual = (Get-ADDomain).DNSRoot

    try {
        # Creacion del usuario especificando cambio obligatorio de clave
        New-ADUser -Name "$nombre $apellidos" `
                   -GivenName $nombre `
                   -Surname $apellidos `
                   -SamAccountName $login `
                   -UserPrincipalName "$login@$dominioActual" `
                   -Path $ouDestino `
                   -AccountPassword $claveSecreta `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true

        # Vinculacion al grupo
        Add-ADGroupMember -Identity $grupoAsignado -Members $login

        Write-Host "`n++ Usuario '$login' creado e integrado en '$grupoAsignado' ++" -ForegroundColor Green
    }
    catch {
        Write-Host "`n-- Error durante el alta del usuario: $_ --" -ForegroundColor Red
    }

    Write-Host "`nPulse [ENTER] para regresar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadLine()
}

# Bucle del Menu
$seleccion = 0

while ($seleccion -ne 5) {
    Clear-Host
    Write-Host "**************************************************" -ForegroundColor DarkCyan
    Write-Host "    PANEL DE CONTROL - ACTIVE DIRECTORY ADMIN     " -ForegroundColor White
    Write-Host "**************************************************" -ForegroundColor DarkCyan
    Write-Host "  [1] Consulta de metricas del dominio"
    Write-Host "  [2] Alta de Unidad Organizativa (OU)"
    Write-Host "  [3] Alta de Grupo de Seguridad"
    Write-Host "  [4] Alta de Usuario"
    Write-Host "  [5] Salir"
    Write-Host "**************************************************" -ForegroundColor DarkCyan
    
    $seleccion = Read-Host "Opcion seleccionada"

    switch ($seleccion) {
        "1" { Obtener-ResumenDominio }
        "2" { Nueva-UnidadOrganizativa }
        "3" { Nuevo-GrupoSeguridad }
        "4" { Nuevo-UsuarioAD }
        "5" { Write-Host "`nCerrando sesion de administracion..." -ForegroundColor DarkCyan }
        default { 
            Write-Host "`n[!] Entrada no valida. Seleccione una opcion entre 1 y 5." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}