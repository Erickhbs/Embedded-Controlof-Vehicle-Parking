class Vagas {
  int estado;
  int cor;
  bool reserva;

  Vagas({
    required this.estado,
    required this.cor,
    required this.reserva,
  });
    
  changeColor(cor){
    this.cor = cor;
  }

  changeEstado(estado){
    this.estado = estado;
  }

  changeReserva(reserva){
    this.reserva = reserva;
  }

}