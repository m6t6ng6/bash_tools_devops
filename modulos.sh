#############
# IMPRIMIR MENSAJES CON COLORES PARA LA CONSOLA
# EJEMPLO DE USO: 
#       print_message $RED "Instalando paquete"
#

# colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;94m'
NC='\033[0m' # no color

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"  # flag -e es necesario para que muestre con colores
}
#############
# CHEQUEA QUE LAS HERRAMIENTAS ESTEN INSTALADAS EN EL OS
# EJEMPLO DE USO:  
#       array_de_programas=("docker" "jq" "git")
#       check_tools "${array_de_programas[@]}"
#

check_tools() {
    local array=("$@")
    for programa in "${array[@]}"; do
        if command -v $programa &>/dev/null; then
            print_message $GREEN "\u2714 $programa is installed"
        else
            print_message $RED "\u2718 $programa is not installed"
            exit 1
        fi
    done
}
#############
# CHEQUE LA INFORMACION DEL REPOSITORIO DE GIT Y LA IMAGEN DE DOCKER A USAR
# EJEMPLO DE USO:  
#       ci_cd_info
#

ci_cd_info() {
    # Obtener la última rama en la que se hizo el commit
    BRANCH=$(git rev-parse --abbrev-ref HEAD)

    # Obtener el último commit hecho en la rama actual
    LAST_COMMIT=$(git log -1 --pretty=format:"%h")

    # Obtener el nombre del autor del último commit
    AUTHOR=$(git log -1 --pretty=format:"%an")

    # Obtener el correo del autor del último commit
    EMAIL=$(git log -1 --pretty=format:"%ae")

    declare -A automation_info=(
        ['AUTOMATION_INFO_1']=$(print_message $GREEN ">>> AUTOMATION: commit ${LAST_COMMIT}")
        ['AUTOMATION_INFO_2']=$(print_message $YELLOW "on branch ${BRANCH}")
        ['AUTOMATION_INFO_3']=$(print_message $BLUE "by ${AUTHOR}")
    )

    echo -e ""
    echo -e "${automation_info['AUTOMATION_INFO_1']} ${automation_info['AUTOMATION_INFO_2']} ${automation_info['AUTOMATION_INFO_3']}"
    echo -e ""

    # Datos a mostrar (puedes agregar o modificar los campos aquí)
    ERROR="n/a"
    declare -A info=(
        ["GIT_SHORT"]=$(git rev-parse --short HEAD 2>/dev/null || echo ${ERROR})
        ["BRANCH_NAME"]=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ${ERROR})
        ["VERSION"]=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null || echo ${ERROR})
        ["REGISTRY"]=$(git config --get remote.origin.url 2>/dev/null || echo ${ERROR})
        ["REPOSITORY"]=$(basename -s .git `git config --get remote.origin.url` 2>/dev/null || echo ${ERROR})
        ["DOCKER IMAGE"]=$(docker images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | tr '\n' ','| sed 's/,$//' || echo ${ERROR})
        ["GIT_USER"]=$(git log -1 --pretty=format:"%an" 2>/dev/null || echo ${ERROR})
        ["GIT_USER_EMAIL"]=$(git log -1 --pretty=format:"%ae" 2>/dev/null || echo ${ERROR})
    )

    # Calcular el ancho máximo de cada columna
    max_key_length=0
    max_value_length=0
    for key in "${!info[@]}"; do
        key_length=${#key}
        value_length=${#info[$key]}
        if (( key_length > max_key_length )); then
            max_key_length=$key_length
        fi
        if (( value_length > max_value_length )); then
            max_value_length=$value_length
        fi
    done

    # Añadir margen adicional
    max_key_length=$((max_key_length + 2))
    max_value_length=$((max_value_length + 2))

    # Calcular el ancho total para el header (ambas columnas + separador)
    total_width=$((max_key_length + max_value_length + 1))

    # Imprimir la línea superior
    print_line() {
        printf "╔"
        for ((i=0; i<total_width; i++)); do
            printf "═"
        done
        printf "╗\n"
    }

    # Imprimir la línea divisoria entre el header y la tabla
    print_header_divider() {
        printf "╠"
        for ((i=0; i<max_key_length; i++)); do
            printf "═"
        done
        printf "╦"
        for ((i=0; i<max_value_length; i++)); do
            printf "═"
        done
        printf "╣\n"
    }

    # Imprimir la línea inferior que apunte hacia arriba
    print_line_up() {
        printf "╚"
        for ((i=0; i<max_key_length; i++)); do
            printf "═"
        done
        printf "╩"
        for ((i=0; i<max_value_length; i++)); do
            printf "═"
        done
        printf "╝\n"
    }

    # Imprimir una línea con contenido centrado en el header
    print_header() {
        local text="INFORMATION"
        local padding=$(( (total_width - ${#text}) / 2 ))
        printf "║"
        for ((i=0; i<padding; i++)); do
            printf " "
        done
        printf "%s" "$text"
        for ((i=0; i<total_width - padding - ${#text}; i++)); do
            printf " "
        done
        printf "║\n"
    }

    # Imprimir una línea con contenido alineado a la izquierda
    print_content() {
        local key="$1"
        local value="$2"
        local color="$3"

        # Formato de la columna de la key
        printf "$color║ %-*s" "$((max_key_length - 1))" "$key"
        # Formato de la columna de valor
        printf "║ %-*s" "$((max_value_length - 1))" "$value"
        printf "║\e[0m\n"
    }

    # Imprimir el cuadro completo
    print_line
    print_header
    print_header_divider
    row_count=0
    for key in "${!info[@]}"; do
        if (( row_count % 2 == 0 )); then
            # Fondo gris oscuro tenue (casi negro) y texto blanco para filas impares
            color="\e[40m\e[97m"
        else
            # Fondo normal y texto blanco para filas pares
            color="\e[49m\e[97m"
        fi
        print_content "$key" "${info[$key]}" "$color"
        ((row_count++))
    done
    print_line_up
    echo -e
}
#############