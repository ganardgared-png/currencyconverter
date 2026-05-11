part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object> get props => [];
}

class LoadHomeData extends HomeEvent {}

class UpdateIncome extends HomeEvent {
  final double income;
  final String incomeType;
  
  const UpdateIncome({required this.income, required this.incomeType});
  
  @override
  List<Object> get props => [income, incomeType];
}

class RefreshHomeData extends HomeEvent {}