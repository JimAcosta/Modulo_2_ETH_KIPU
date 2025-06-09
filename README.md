Trabajo Final - Módulo 2: Contrato Inteligente de Subasta

Este proyecto implementa un contrato inteligente de una subasta desarrollado en Solidity, cumpliendo con todos los requisitos del módulo.
Estructura del Contrato

El contrato se llama Subasta y permite gestionar una subasta pública con múltiples participantes.
Variables Principales

    propietario: Dirección del usuario que despliega el contrato. Solo él puede finalizar la subasta.

    duracion: Duración de la subasta en segundos.

    inicio: Fecha y hora en la que comienza la subasta (timestamp del bloque).

    mejorOferta: Monto actual de la mejor oferta.

    mejorOferente: Dirección del usuario que hizo la mejor oferta.

    finalizada: Booleano que indica si la subasta ya fue finalizada.

    ofertas: Un mapping que asocia cada dirección con un array de valores ofertados.

    saldoPendiente: Un mapping que permite gestionar los excesos de depósitos, útiles para reembolso parcial durante la subasta.

Constructor

constructor(uint256 _duracionSegundos)

Este constructor se ejecuta al momento de desplegar el contrato y define la duración de la subasta. También registra al propietario (quien despliega el contrato) y el tiempo de inicio usando block.timestamp.
Modificadores

    soloDuranteSubasta: Restringe el uso de funciones a cuando la subasta esté activa. Verifica que el tiempo actual esté dentro del periodo permitido y que la subasta no haya finalizado.

    soloPropietario: Restringe ciertas funciones solo al propietario del contrato.

Función ofertar()

function ofertar() public payable soloDuranteSubasta

Permite a cualquier usuario enviar una oferta. La función verifica que el monto enviado sea al menos un 5% mayor que la oferta actual más alta. Si se realiza una oferta dentro de los últimos 10 minutos de la subasta, el tiempo se extiende 10 minutos adicionales para permitir competencia justa.

Además, esta función:

    Guarda el exceso respecto a la oferta anterior para permitir un reembolso parcial.

    Actualiza al mejor oferente.

    Emite un evento NuevaOferta.

Función retirarExceso()

function retirarExceso() public

Permite a los usuarios retirar el exceso de fondos depositados que no forman parte de su última oferta válida. Esta lógica es parte de la funcionalidad avanzada y previene el bloqueo innecesario de fondos.
Función obtenerGanador()

function obtenerGanador() public view returns (address, uint256)

Devuelve la dirección del mejor oferente y el monto que ofertó. No modifica el estado del contrato y es de solo lectura.
Función obtenerOfertas(address _oferente)

function obtenerOfertas(address _oferente) public view returns (uint256[] memory)

Permite consultar todas las ofertas que una dirección determinada realizó durante la subasta.
Función finalizarSubasta()

function finalizarSubasta() public soloPropietario

Finaliza la subasta. Esta función puede ser llamada únicamente por el propietario del contrato. Realiza lo siguiente:

    Marca la subasta como finalizada.

    Devuelve los depósitos a todos los participantes que no ganaron, reteniendo una comisión del 2% sobre cada uno.

    No devuelve el monto ofertado por el ganador, ya que se considera la compra.

    Emite el evento SubastaFinalizada.

Eventos

    NuevaOferta(address oferente, uint256 monto): Se emite cada vez que se realiza una nueva oferta válida.

    SubastaFinalizada(address ganador, uint256 monto): Se emite cuando el propietario finaliza la subasta.

Comisiones y Reembolsos

    El contrato retiene un 2% de comisión de las ofertas de los no ganadores al finalizar la subasta.

    Durante la subasta, los usuarios pueden retirar el exceso de sus ofertas anteriores (esto es parte de la funcionalidad avanzada).

Seguridad y Buenas Prácticas

    Validación estricta de los estados y condiciones con require.

    Accesos restringidos con modificadores.

    Lógica para evitar condiciones de carrera y problemas de seguridad como el reingreso (no se hacen llamadas externas sin actualizar el estado antes).

    Uso de mapping para manejar depósitos de forma segura y trazable.

Consideraciones Finales

    El contrato está diseñado para cumplir todos los requisitos del módulo: constructor, funciones para ofertar, mostrar ganador, mostrar historial de ofertas, devolver depósitos, manejar depósitos, emitir eventos y permitir reembolso parcial.

    Se utilizaron modificadores para mantener la lógica ordenada y legible.

    Toda la lógica de validación y reembolso fue cuidadosamente diseñada para evitar errores de seguridad y permitir el uso seguro por parte de múltiples usuarios.