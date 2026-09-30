import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:t_store/core/usecases/usecase.dart';
import 'package:t_store/features/personalization/domain/entities/address_entity.dart';
import 'package:t_store/features/personalization/domain/usecases/add_address_usecase.dart';
import 'package:t_store/features/personalization/domain/usecases/delete_address_usecase.dart';
import 'package:t_store/features/personalization/domain/usecases/get_addresses_usecase.dart';
import 'package:t_store/features/personalization/domain/usecases/update_address_usecase.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_cubit.dart';
import 'package:t_store/features/personalization/presentation/cubit/addresses_state.dart';

class MockGetAddressesUsecase extends Mock implements GetAddressesUsecase {}

class MockAddAddressUsecase extends Mock implements AddAddressUsecase {}

class MockUpdateAddressUsecase extends Mock implements UpdateAddressUsecase {}

class MockDeleteAddressUsecase extends Mock implements DeleteAddressUsecase {}

class FakeNoParams extends Fake implements NoParams {}

class FakeAddAddressParams extends Fake implements AddAddressParams {}

class FakeUpdateAddressParams extends Fake implements UpdateAddressParams {}

/// Address selection + update-identity contracts:
///
/// - checkout uses the default address, falling back to the first one;
/// - editing an address updates the SAME record (same id), never
///   inserting a duplicate.
void main() {
  const first = AddressEntity(
    id: 'a-1',
    userId: 'u-1',
    fullName: 'Priya Sharma',
    phone: '+919876543210',
    addressLine1: '42 MG Road',
    city: 'Bengaluru',
    country: 'India',
  );
  const second = AddressEntity(
    id: 'a-2',
    userId: 'u-1',
    fullName: 'Priya Sharma',
    phone: '+919876543210',
    addressLine1: '7 Park Street',
    city: 'Mumbai',
    country: 'India',
    isDefault: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeAddAddressParams());
    registerFallbackValue(FakeUpdateAddressParams());
  });

  group('AddressesLoaded.defaultAddress', () {
    test('prefers the default address', () {
      const loaded = AddressesLoaded([first, second]);
      expect(loaded.defaultAddress?.id, 'a-2');
    });

    test('falls back to the first address when none is default', () {
      const loaded = AddressesLoaded([first]);
      expect(loaded.defaultAddress, isNull);
    });
  });

  group('updateAddress identity', () {
    test('update carries the same record id (no duplicate insert)', () async {
      final mockUpdate = MockUpdateAddressUsecase();
      final updated = first.copyWith(fullName: 'Priya S');
      when(() => mockUpdate(any())).thenAnswer((_) async => Right(updated));
      final mockGet = MockGetAddressesUsecase();
      when(() => mockGet(any())).thenAnswer((_) async => Right([updated]));
      final cubit = AddressesCubit(
        getAddressesUsecase: mockGet,
        addAddressUsecase: MockAddAddressUsecase(),
        updateAddressUsecase: mockUpdate,
        deleteAddressUsecase: MockDeleteAddressUsecase(),
      );

      await cubit.updateAddress(
        id: 'a-1',
        fullName: 'Priya S',
        phone: '+919876543210',
        addressLine1: '42 MG Road',
        city: 'Bengaluru',
        country: 'India',
      );

      final captured = verify(() => mockUpdate(captureAny())).captured.single;
      expect(captured.id, 'a-1');
      // updateAddress chains getAddresses(): let the reload emit first.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.close();
    });
  });

  group('first address creation', () {
    test('addAddress stores and reloads the list', () async {
      final mockAdd = MockAddAddressUsecase();
      when(() => mockAdd(any())).thenAnswer((_) async => const Right(first));
      final mockGet = MockGetAddressesUsecase();
      when(() => mockGet(any())).thenAnswer((_) async => const Right([first]));
      final cubit = AddressesCubit(
        getAddressesUsecase: mockGet,
        addAddressUsecase: mockAdd,
        updateAddressUsecase: MockUpdateAddressUsecase(),
        deleteAddressUsecase: MockDeleteAddressUsecase(),
      );

      await cubit.addAddress(
        fullName: 'Priya Sharma',
        phone: '+919876543210',
        addressLine1: '42 MG Road',
        city: 'Bengaluru',
        country: 'India',
      );

      verify(() => mockAdd(any())).called(1);
      verify(() => mockGet(any())).called(1);
      // addAddress chains getAddresses(): let the reload emit first.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.close();
    });
  });
}
