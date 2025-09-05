# ReentrancyGuard - OpenZeppelin

**Protección contra reentrancia en contratos inteligentes**

---
## 📜 Descripción

`ReentrancyGuard` es un contrato abstracto de **OpenZeppelin** (v5.1.0) diseñado para prevenir ataques de **reentrancia** (reentrancy) en funciones críticas de un contrato inteligente. Este tipo de ataque ocurre cuando una función externa maliciosa realiza llamadas recursivas a una función del contrato antes de que la ejecución original finalice, lo que puede llevar a:
- **Robo de fondos** (ejemplo clásico: el ataque a The DAO en 2016).
- **Inconsistencias en el estado** del contrato.

### ¿Cómo funciona?
- Utiliza un **modificador `nonReentrant`** que bloquea el acceso a funciones marcadas mientras están en ejecución.
- Internamente, usa un **estado (`_status`)** con dos valores posibles:
  - `NOT_ENTERED` (1): La función no está siendo ejecutada.
  - `ENTERED` (2): La función está en ejecución (bloquea nuevas llamadas).
- Si se intenta llamar a una función `nonReentrant` mientras otra ejecución está en curso, el contrato **revertirá** con el error `ReentrancyGuardReentrantCall`.

### 🔹 Casos de uso
- Funciones que manejan **transferencias de tokens** (ej: `withdraw`, `deposit`).
- Funciones que modifican **estados críticos** (ej: balances, contadores).
- Cualquier función donde una llamada externa pueda reingresar al contrato antes de finalizar.

---
## 🚀 Despliegue

### Requisitos previos
1. **Entorno de desarrollo**:
   - [Remix IDE](https://remix.ethereum.org/) (recomendado para pruebas rápidas).

2. **Dependencias**:
   - Instalar `@openzeppelin/contracts` (v5.1.0 o superior):
     ```bash
     npm install @openzeppelin/contracts@5.1.0
     ```

### Pasos para desplegar
#### Opción 1: Usando Remix IDE
1. **Abrir Remix** y clonar el proyecto

2. **Compilar:**
    - Seleccionar el compilador Solidity 0.8.30+.
    - Hacer clic en "Compile".

3. **Desplegar KipuBank.sol:**
    - Ir a la pestaña "Deploy & Run".
    - Seleccionar el entorno (ej: Injected Web3 para MetaMask o JavaScript VM para pruebas locales).
    - Ingresar bankCap
    - Hacer clic en "Deploy".
    - Copiar address del contrato
    
4. **Publicar en testnet**
    - Ingresar a https://sepolia.etherscan.io/
    - Buscar address del contrato
    - En Contracts, completar Verify & Publish

