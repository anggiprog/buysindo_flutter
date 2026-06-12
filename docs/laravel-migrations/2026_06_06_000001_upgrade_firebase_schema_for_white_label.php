<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('firebase_projects', function (Blueprint $table) {
            $table->string('google_project_id')->nullable()->after('project_name');
            $table->string('google_project_number')->nullable()->after('google_project_id');
            $table->string('display_name')->nullable()->after('google_project_number');
            $table->string('allocation_mode', 20)->default('shared')->after('display_name');
            $table->string('status', 30)->default('active')->after('allocation_mode');
            $table->unsignedSmallInteger('soft_app_limit')->default(25)->after('status');
            $table->unsignedSmallInteger('hard_app_limit')->default(30)->after('soft_app_limit');
            $table->unsignedSmallInteger('registered_app_count')->default(0)->after('hard_app_limit');
            $table->unsignedSmallInteger('reserved_app_count')->default(0)->after('registered_app_count');
            $table->string('credential_reference', 500)->nullable()->after('service_account_path');
            $table->text('last_error')->nullable()->after('credential_reference');
            $table->timestamp('last_reconciled_at')->nullable()->after('last_error');
            $table->timestamp('updated_at')->nullable()->after('created_at');

            $table->unique('google_project_id', 'firebase_projects_google_project_id_unique');
            $table->unique('google_project_number', 'firebase_projects_project_number_unique');
            $table->index(
                ['status', 'allocation_mode', 'registered_app_count'],
                'firebase_projects_pool_lookup'
            );
        });

        Schema::create('firebase_android_apps', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->integer('admin_user_id');
            $table->integer('firebase_project_id');
            $table->integer('application_id')->nullable();
            $table->bigInteger('app_config_id')->nullable();
            $table->string('package_name')->unique();
            $table->string('display_name');
            $table->string('firebase_app_id')->nullable()->unique();
            $table->string('firebase_resource_name')->nullable()->unique();
            $table->string('status', 30)->default('reserved');
            $table->longText('google_services_json_encrypted')->nullable();
            $table->char('config_sha256', 64)->nullable();
            $table->string('operation_name', 500)->nullable();
            $table->unsignedInteger('provision_attempts')->default(0);
            $table->text('last_error')->nullable();
            $table->timestamp('provisioned_at')->nullable();
            $table->timestamps();

            $table->foreign('admin_user_id', 'firebase_android_apps_admin_fk')
                ->references('id')->on('admin_users')->cascadeOnDelete();
            $table->foreign('firebase_project_id', 'firebase_android_apps_project_fk')
                ->references('id')->on('firebase_projects')->restrictOnDelete();
            $table->foreign('application_id', 'firebase_android_apps_application_fk')
                ->references('id')->on('applications')->nullOnDelete();
            $table->foreign('app_config_id', 'firebase_android_apps_config_fk')
                ->references('id')->on('app_configs')->nullOnDelete();

            $table->unique(
                ['admin_user_id', 'package_name'],
                'firebase_android_apps_tenant_package_unique'
            );
            $table->index(
                ['firebase_project_id', 'status'],
                'firebase_android_apps_project_status'
            );
        });

        Schema::create('device_installations', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->integer('admin_user_id');
            $table->unsignedBigInteger('firebase_android_app_id');
            $table->integer('user_id')->nullable();
            $table->string('installation_id', 80);
            $table->text('fcm_token')->nullable();
            $table->char('fcm_token_hash', 64)->nullable()->unique();
            $table->string('package_name');
            $table->string('firebase_app_id');
            $table->string('platform', 20)->default('android');
            $table->string('app_version', 50)->nullable();
            $table->string('app_build_number', 50)->nullable();
            $table->string('status', 20)->default('active');
            $table->timestamp('token_refreshed_at')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamp('last_delivery_at')->nullable();
            $table->timestamp('invalidated_at')->nullable();
            $table->timestamps();

            $table->foreign('admin_user_id', 'device_installations_admin_fk')
                ->references('id')->on('admin_users')->cascadeOnDelete();
            $table->foreign('firebase_android_app_id', 'device_installations_app_fk')
                ->references('id')->on('firebase_android_apps')->cascadeOnDelete();
            $table->foreign('user_id', 'device_installations_user_fk')
                ->references('id')->on('users')->nullOnDelete();

            $table->unique(
                ['firebase_android_app_id', 'installation_id'],
                'device_installations_app_installation_unique'
            );
            $table->index(['user_id', 'status'], 'device_installations_user_status');
            $table->index(['admin_user_id', 'status'], 'device_installations_tenant_status');
        });

        Schema::table('applications', function (Blueprint $table) {
            $table->unsignedBigInteger('firebase_android_app_id')
                ->nullable()
                ->after('paket_name');
            $table->index(
                'firebase_android_app_id',
                'applications_firebase_android_app_index'
            );
        });

        Schema::table('app_configs', function (Blueprint $table) {
            $table->unsignedBigInteger('firebase_android_app_id')
                ->nullable()
                ->after('admin_user_id');
            $table->index(
                'firebase_android_app_id',
                'app_configs_firebase_android_app_index'
            );
        });

        Schema::table('firebase_admin', function (Blueprint $table) {
            $table->integer('firebase_project_id')
                ->nullable()
                ->after('admin_user_id');
            $table->unsignedBigInteger('firebase_android_app_id')
                ->nullable()
                ->after('firebase_project_id');
            $table->index('firebase_project_id', 'firebase_admin_project_index');
            $table->index('firebase_android_app_id', 'firebase_admin_app_index');
        });
    }

    public function down(): void
    {
        Schema::table('firebase_admin', function (Blueprint $table) {
            $table->dropIndex('firebase_admin_project_index');
            $table->dropIndex('firebase_admin_app_index');
            $table->dropColumn(['firebase_project_id', 'firebase_android_app_id']);
        });

        Schema::table('app_configs', function (Blueprint $table) {
            $table->dropIndex('app_configs_firebase_android_app_index');
            $table->dropColumn('firebase_android_app_id');
        });

        Schema::table('applications', function (Blueprint $table) {
            $table->dropIndex('applications_firebase_android_app_index');
            $table->dropColumn('firebase_android_app_id');
        });

        Schema::dropIfExists('device_installations');
        Schema::dropIfExists('firebase_android_apps');

        Schema::table('firebase_projects', function (Blueprint $table) {
            $table->dropUnique('firebase_projects_google_project_id_unique');
            $table->dropUnique('firebase_projects_project_number_unique');
            $table->dropIndex('firebase_projects_pool_lookup');
            $table->dropColumn([
                'google_project_id',
                'google_project_number',
                'display_name',
                'allocation_mode',
                'status',
                'soft_app_limit',
                'hard_app_limit',
                'registered_app_count',
                'reserved_app_count',
                'credential_reference',
                'last_error',
                'last_reconciled_at',
                'updated_at',
            ]);
        });
    }
};
