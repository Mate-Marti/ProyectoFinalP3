defmodule Usuario do

  defstruct [:username, :password, :nombre_completo, :rol, :zona_principal]

  def crear_usuario(username, password, nombre_completo, rol, zona) when rol in [:ciudadano, :voluntario, :coordinador, :administrador] do
    %Usuario{
      username: username,
      password: password,
      nombre_completo: nombre_completo,
      rol: rol,
      zona_principal: zona
    }
  end
end
