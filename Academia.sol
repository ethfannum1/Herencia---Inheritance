// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


/* 
-----------------------------------------------------------------------------------------------------------------------
¿Por qué usar interfaces y contratos abstractos? 
 
- Interfaces:
para garantizar que se cumplen una serie de: funcionalidades, esquemas, ... (ejemplo: para los estándares: ERC20, ...)

- Contratos Abstractos:
es una manera de programar de forma modular: 
dividir diferentes categorías, funcionalidades, ..., en diferentes contratos, que se van heredando e implementando.
-----------------------------------------------------------------------------------------------------------------------
*/



/*
-----------------------------------------------------------------------------------------------------------------------
Una interfaz sirve para definir una serie de condiciones mínimas que debe cumplir un contrato que herede de ella.

EL contrato en cuestión que hereda de la interfaz, puede tener además otras funciones extras añadidas. 
(En este ejemplo: la función addCount)

Pero una interfaz dice qué funciones como mínimo hay que incluir = implementar.

Las interfaces no implementan el cuerpo de la función, se tienen que implementar en el contrato que hereda de ellas.
Si no se hace, da un error de compilación.

Por eso los estándares (ERC20, etc) se definen a través de interfaces.

Una interfaz puede definir:
    - structs
    - enums
    - events
    - functions


Todo el código de la interfaz que el contrato necesita, queda embebido después dentro del propio código del contrato.
-----------------------------------------------------------------------------------------------------------------------
*/




// -----------------------------------------------------------------------------------------------------------------------------------
// INTERFAZ
// -----------------------------------------------------------------------------------------------------------------------------------
// Todo contrato que herede de una interfaz, tiene que implementar todo lo que la interfaz defina.
interface IEscuela {

    // Este evento se dispara cuando se cree un nuevo estudiante.
    event newStudent(address user);

    enum Rol { teacher, student }

    struct User {
        string name;
        Rol rol;
    }

    /* 
    Interfaces:
    https://docs.soliditylang.org/en/v0.8.0/contracts.html?highlight=interfaces#interfaces

    - Toda función declarada en una interfaz tiene que ser external.

    - En principio la palabra reservada virtual, no es necesario ponerla en la definición de una función dentro de una interfaz:
            All functions declared in interfaces are implicitly virtual, which means that they can be overridden. 
            This does not automatically mean that an overriding function can be overridden again - this is only possible if the overriding function is marked virtual 
    */    
    
    function addUser(address user, string memory name, Rol rol) external returns (bool);

    function changeUserName(address user, string memory newName) external returns (bool);
}
// -----------------------------------------------------------------------------------------------------------------------------------



// -----------------------------------------------------------------------------------------------------------------------------------
// CONTRATO SECUNDARIO
// -----------------------------------------------------------------------------------------------------------------------------------
/*
Este contrato es abstracto.

Un contrato abstracto es aquel que al menos una de sus funciones no está implementada en dicho contrato.
(En este ejemplo: la función ratingTeacher está sólo definida en este contrato, pero no implementada)

A diferencia de la interfaz, las funciones de un contrato abstracto (y en general en cualquier contrato) pueden tener cualquier visibilidad: internal, external, private, public.
Sus funciones no tienen que ser obligatoriamente external como en el caso de la interfaz.

A diferencia de la interfaz, en un contrato abstracto (y en general en cualquier contrato) sí se pueden definir variables de estado.
En una interfaz no.

En general en cualquier contrato, por defecto, las variables de estado tienen visibilidad internal. ¿? (Parece que es así, pero asegurarse)
(En este ejemplo: la variable _ratingsTeachers es internal)

Ojo: si se pone una variable de estado con visibilidad private, sólo podrá ser accesible desde dentro de dicho contrato, no por contratos que hereden de este.
*/
// Es un contrato abstracto porque una de sus funciones (ratingTeacher) no está implementada, sólo definida.
abstract contract RatingsTeachers {

    // Puntuación de cada profesor.
    mapping(address => uint256) _ratingsTeachers;


    // Añadir puntuación a un profesor.
    function addToTeacher(address teacher) public returns (bool) {
        _ratingsTeachers[teacher]++;

        return(true);
    }


    // Retornar la puntuación que tenga un profesor.
    // Esta función solamente se declara. 
    // Será implementada en otro contrato. (por eso el virtual)
    function ratingTeacher(address teacher) public view virtual returns (uint256); 

}



// -----------------------------------------------------------------------------------------------------------------------------------
// CONTRATO SECUNDARIO
// -----------------------------------------------------------------------------------------------------------------------------------
// Es un contrato abstracto porque una de sus funciones (ratingStudent) no está implementada, sólo definida.
abstract contract RatingsStudents {

    // Puntuación de cada estudiante.
    mapping(address => uint256) _ratingsStudents;


    // Añadir puntuación a un estudiante.
    function addToStudent(address student) public returns (bool) {
        _ratingsStudents[student]++;

        return(true);
    }


    // Retornar la puntuación que tenga un estudiante.
    // Esta función solamente se declara. 
    // Será implementada en otro contrato. (por eso el virtual)
    function ratingStudent(address student) public view virtual returns (uint256);

}



// -----------------------------------------------------------------------------------------------------------------------------------
// CONTRATO PRINCIPAL
// -----------------------------------------------------------------------------------------------------------------------------------
// Si este contrato Academia, no implementase las funciones ratingTeacher y ratingStudent, entonces este contrato tendría que ser definido también como abstract.
// Porque al heredar de un contrato abstracto (RatingsTeachers) (RatingsStudents), 
// si no implementa sus funciones virtual (ratingTeacher) (ratingStudent), este contrato Academia pasa también a ser abstracto.
contract Academia is IEscuela, RatingsTeachers, RatingsStudents {

    // Contador de estudiantes.
    uint256 public countStudents;

    // Usuarios, que pueden ser tanto profesores como alumnos.
    mapping(address => User) public users; 


    // Al implementar una función de la interfaz, se pone override.
    function addUser(address user, string memory name, Rol rol) public override returns (bool) {
        // Dar de alta un nuevo usuario.
        users[user] = User(name, rol);

        // Si es un estudiante:
        if (rol == Rol.student) {
            // Incrementar el contador de estudiantes.
            addCount();
            // Lanzar el evento.
            emit newStudent(user);
        }

        return(true);
    }


    // Al implementar una función de la interfaz, se pone override.
    function changeUserName(address user, string memory newName) public override returns (bool) {
        users[user].name = newName;

        return(true);
    }


    // Función del contrato heredado RatingsTeachers, que es virtual en dicho contrato, y que se implementa aquí en este contrato Academia.
    // Por eso aquí se pone override: porque se está implementando una función virtual definida en otro contrato o interfaz (en este caso contrato: RatingsTeachers)
    function ratingTeacher(address teacher) public view override returns (uint256) {
        return(_ratingsTeachers[teacher]);
    } 


    // Función del contrato heredado RatingsStudents, que es virtual en dicho contrato, y que se implementa aquí en este contrato Academia.
    // Por eso aquí se pone override: porque se está implementando una función virtual definida en otro contrato o interfaz (en este caso contrato: RatingsStudents)
    function ratingStudent(address student) public view override returns (uint256) {
        return(_ratingsStudents[student]);
    }


    // Añadir puntuación a un profesor.
    // Mediante la llamada a la función addToTeacher del contrato RatingsTeachers, del cual hereda este contrato Academia.
    /*
    SUPER: 
    Creo que la cosa va así: 
    Si este contrato Academia tuviera una función llamada addRatTeacher, entonces sí sería necesario poner el SUPER 
    para indicar que queremos llamar a la función addRatTeacher pero del contrato padre del que heredamos, y no a la función addRatTeacher de este contrato Academia. 
    Pero en este caso sólo hay una función addRatTeacher que es la del contrato padre, por tanto no es necesario poner la palabra SUPER.
    */
    function addRatTeacher(address teacher) public returns (bool) {
        // super.addRatTeacher(teacher);
        addRatTeacher(teacher);

        return(true);
    }


    function addRatStudent(address student) public returns (bool) {
        // RatingsStudents.addToStudent(student);
        addToStudent(student);

        return(true);
    }
 


    function addCount() private returns (bool) {
        countStudents++;
        return(true);
    }

}
// -----------------------------------------------------------------------------------------------------------------------------------






