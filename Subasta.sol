// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Subasta {
    address public propietario;
    address public mejorOferente;
    uint256 public mejorOferta;
    uint256 public tiempoFinal;
    uint256 public comisionTotal;

    struct Oferta {
        uint256 monto;
        bool retirado;
    }

    mapping(address => Oferta[]) public ofertas;

    event NuevaOferta(address indexed oferente, uint256 monto);
    event SubastaFinalizada(address ganador, uint256 montoGanador);

    modifier soloDuranteSubasta() {
        require(block.timestamp < tiempoFinal, "La subasta ha finalizado.");
        _;
    }

    modifier soloGanador() {
        require(msg.sender == mejorOferente, "No sos el ganador.");
        _;
    }

    constructor(uint256 _duracionSegundos) {
        propietario = msg.sender;
        tiempoFinal = block.timestamp + _duracionSegundos;
    }

    function ofertar() external payable soloDuranteSubasta {
        require(msg.value > 0, "La oferta debe ser mayor a 0.");

        uint256 totalOferta = obtenerTotalOfertado(msg.sender) + msg.value;

        // Verifica que la nueva oferta sea al menos un 5% mayor a la mejor actual
        require(
            mejorOferente == address(0) || totalOferta >= mejorOferta + (mejorOferta * 5) / 100,
            "La oferta debe ser al menos un 5% mayor que la mejor oferta."
        );

        // Extiende el tiempo de la subasta si la oferta se realiza en los ultimos 10 minutos
        if (tiempoFinal - block.timestamp <= 10 minutes) {
            tiempoFinal += 10 minutes;
        }

        ofertas[msg.sender].push(Oferta(msg.value, false));

        mejorOferente = msg.sender;
        mejorOferta = totalOferta;

        emit NuevaOferta(msg.sender, totalOferta);
    }

    function obtenerGanador() external view returns (address, uint256) {
        require(block.timestamp >= tiempoFinal, "La subasta sigue activa.");
        return (mejorOferente, mejorOferta);
    }

    function obtenerOfertas(address _oferente) external view returns (Oferta[] memory) {
        return ofertas[_oferente];
    }

    function retirarExcedente() external {
        uint256 excedente = 0;
        uint256 sumaOfertas = 0;

        for (uint i = 0; i < ofertas[msg.sender].length; i++) {
            if (!ofertas[msg.sender][i].retirado) {
                sumaOfertas += ofertas[msg.sender][i].monto;
            }
        }

        if (msg.sender == mejorOferente) {
            require(sumaOfertas > mejorOferta, "No hay excedente para retirar.");
            excedente = sumaOfertas - mejorOferta;
        } else {
            excedente = sumaOfertas;
        }

        require(excedente > 0, "No hay nada para retirar.");

        for (uint i = 0; i < ofertas[msg.sender].length; i++) {
            ofertas[msg.sender][i].retirado = true;
        }

        uint256 comision = (excedente * 2) / 100;
        comisionTotal += comision;

        payable(msg.sender).transfer(excedente - comision);
    }

    function finalizarSubasta() external {
        require(block.timestamp >= tiempoFinal, "La subasta aun no ha finalizado.");
        require(msg.sender == propietario, "Solo el propietario puede finalizar la subasta.");

        for (uint i = 0; i < ofertas[mejorOferente].length; i++) {
            ofertas[mejorOferente][i].retirado = true;
        }

        emit SubastaFinalizada(mejorOferente, mejorOferta);
    }

    function obtenerTotalOfertado(address _oferente) internal view returns (uint256 total) {
        for (uint i = 0; i < ofertas[_oferente].length; i++) {
            if (!ofertas[_oferente][i].retirado) {
                total += ofertas[_oferente][i].monto;
            }
        }
    }
}
