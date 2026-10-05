"""
Setup development/demo accounts for TAMS:
ADMIN:    admin@tams.local    / TamsAdmin@123
STAFF:    staff@tams.local    / TamsStaff@123
DRIVER:   driver@tams.local   / TamsDriver@123
CUSTOMER: customer@tams.local / TamsCustomer@123
"""
import os
import django
from datetime import date, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tams.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from drivers.models import Driver
from bookings.models import Customer

User = get_user_model()

ACCOUNTS = [
    {
        'role': User.Role.ADMIN,
        'email': 'admin@tams.local',
        'username': 'admin_local',
        'password': 'TamsAdmin@123',
        'first_name': 'System',
        'last_name': 'Admin',
        'phone': '9876500000',
        'is_superuser': True,
        'is_staff': True,
    },
    {
        'role': User.Role.STAFF,
        'email': 'staff@tams.local',
        'username': 'staff_local',
        'password': 'TamsStaff@123',
        'first_name': 'Operations',
        'last_name': 'Staff',
        'phone': '9876500003',
        'is_superuser': False,
        'is_staff': True,
    },
    {
        'role': User.Role.DRIVER,
        'email': 'driver@tams.local',
        'username': 'driver_local',
        'password': 'TamsDriver@123',
        'first_name': 'Rajesh',
        'last_name': 'Kumar',
        'phone': '9876500001',
        'is_superuser': False,
        'is_staff': False,
        'driver_profile': {
            'driver_id': 'DRV-101',
            'name': 'Rajesh Kumar',
            'license_number': 'OD-2022-DEMO01',
            'license_expiry': date.today() + timedelta(days=365),
            'experience_years': 5,
            'blood_group': 'B+',
            'address': 'Khandagiri, Bhubaneswar, Odisha',
            'status': Driver.Status.AVAILABLE,
        }
    },
    {
        'role': User.Role.CUSTOMER,
        'email': 'customer@tams.local',
        'username': 'customer_local',
        'password': 'TamsCustomer@123',
        'first_name': 'Ananya',
        'last_name': 'Patnaik',
        'phone': '9876500002',
        'is_superuser': False,
        'is_staff': False,
        'customer_profile': {
            'name': 'Ananya Patnaik',
            'address': 'Nayapalli, Bhubaneswar, Odisha',
            'identity_type': 'Aadhaar Card',
            'identity_number': '1234-5678-9012',
        }
    },
]

def setup():
    results = {}
    print("=" * 60)
    print("CONFIGURING TAMS DEMO ACCOUNTS")
    print("=" * 60)

    for acc in ACCOUNTS:
        role = acc['role']
        email = acc['email']
        password = acc['password']
        try:
            user = User.objects.filter(email__iexact=email).first()
            status_text = 'ALREADY EXISTS'
            if not user:
                user = User(
                    username=acc['username'],
                    email=email,
                    role=role,
                    first_name=acc['first_name'],
                    last_name=acc['last_name'],
                    phone=acc['phone'],
                    is_superuser=acc['is_superuser'],
                    is_staff=acc['is_staff'],
                )
                user.set_password(password)
                user.save()
                status_text = 'CREATED'
            else:
                user.set_password(password)
                user.role = role
                user.is_superuser = acc['is_superuser']
                user.is_staff = acc['is_staff']
                user.save()
                status_text = 'UPDATED'

            # Ensure Auth Token exists
            Token.objects.get_or_create(user=user)

            # Driver profile
            if 'driver_profile' in acc:
                dp = acc['driver_profile']
                driver, d_created = Driver.objects.get_or_create(
                    user=user,
                    defaults={
                        'driver_id': dp['driver_id'],
                        'name': dp['name'],
                        'phone': acc['phone'],
                        'email': email,
                        'license_number': dp['license_number'],
                        'license_expiry': dp['license_expiry'],
                        'experience_years': dp['experience_years'],
                        'blood_group': dp['blood_group'],
                        'address': dp['address'],
                        'status': dp['status'],
                    }
                )
                if not d_created:
                    driver.email = email
                    driver.phone = acc['phone']
                    driver.license_expiry = dp['license_expiry']
                    driver.save()

            # Customer profile
            if 'customer_profile' in acc:
                cp = acc['customer_profile']
                cust, c_created = Customer.objects.get_or_create(
                    user=user,
                    defaults={
                        'name': cp['name'],
                        'email': email,
                        'phone': acc['phone'],
                        'address': cp['address'],
                        'identity_type': cp['identity_type'],
                        'identity_number': cp['identity_number'],
                    }
                )
                if not c_created:
                    cust.email = email
                    cust.phone = acc['phone']
                    cust.save()

            results[role] = status_text
            print(f"[{role}] {email}: {status_text}")
        except Exception as e:
            results[role] = f"FAILED: {e}"
            print(f"[{role}] {email}: FAILED: {e}")

    print("=" * 60)
    return results

if __name__ == '__main__':
    setup()
